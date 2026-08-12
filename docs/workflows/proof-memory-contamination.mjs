// Evidence script for docs/workflows/fix-paid-memory-contamination.md §3.
// Not part of the supabase/tests suite (nothing here is SQL) and not wired
// into any CI — kept as the reproducible source of that document's numbers.
//
// To re-run: point PGHOST/PGPORT/PGUSER/database in the pg.Pool below at any
// throwaway Postgres (never production), then from an empty npm project:
//   npm install --legacy-peer-deps "@langchain/core@0.3.66" "@langchain/community@0.3.49" pg langchain
//   node proof-memory-contamination.mjs
//
// Non-production, non-n8n reproduction of exactly the mechanism
// @n8n/n8n-nodes-langchain.memoryPostgresChat wraps: LangChain's
// PostgresChatMessageHistory (same schema: id serial, session_id, message
// jsonb) + BufferWindowMemory, whose saveContext() persists ONLY the two
// values it is handed as {input, output} — verified directly from the
// installed package source at
// node_modules/langchain/dist/memory/chat_memory.js (BaseChatMemory.saveContext)
// and node_modules/@langchain/community/dist/stores/message/postgres.js
// (PostgresChatMessageHistory.addMessage), both quoted in the review.
//
// This script runs the REAL library code the node runs, against a
// disposable local Postgres. No n8n process, no production database,
// no live workflow, no LLM call — the "model" is a stub that returns a
// canned reply and records exactly what final prompt it was given, which
// is what proves nothing needed by ADAM disappears.

import pg from "pg";
import { BufferWindowMemory } from "langchain/memory";
import { PostgresChatMessageHistory } from "@langchain/community/stores/message/postgres";

const pool = new pg.Pool({
  host: "/tmp/adam_memtest_pg_sock",
  port: 5545,
  user: "postgres",
  database: "memtest",
});

function historyFor(sessionId, tableName) {
  return new PostgresChatMessageHistory({ tableName, sessionId, pool });
}

// A fake "family_context" that changes turn to turn, the way the real
// get_agent_bundle() output does as knowledge_depth grows.
const familyContextByTurn = [
  "[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]\nلا شيء مسجّل عن هذا البيت بعد.\n\n[ما يُسمح لك أن تدّعي معرفته]\nلا تعرف عن هذا البيت شيئاً بعد.",
  "[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]\n== CHILDREN ==\n- يوسف\n\n[ما يُسمح لك أن تدّعي معرفته]\nتعرف اسم الطفل فقط.",
  "[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]\n== CHILDREN ==\n- يوسف\n== PATTERNS ==\n- [confirmed x4] رفض النوم\n\n[ما يُسمح لك أن تدّعي معرفته]\nتعرف الاسم وما يُتعب عادةً.",
];

const parentMessages = [
  "ابني ما ينامش الليل",
  "اسمه يوسف",
  "رجع نفس الشي رفض ينام",
];

const STATIC_SYSTEM_PROMPT = "أنت آدم. مرافقٌ لأهلٍ متعبين.";

// --- helper: what the CURRENT live node does today ------------------------
// text = family_context + "\n\n[رسالة الأهل الآن]\n" + message_text
// systemMessage = STATIC_SYSTEM_PROMPT (no family_context in it at all today
// in the pre-migration-170000 world; but even in the current live node the
// point under test is what gets memorized, which is driven by `text`)
async function currentTurn(memory, familyContext, messageText) {
  const text = (familyContext ? familyContext + "\n\n[رسالة الأهل الآن]\n" : "") + messageText;
  const vars = await memory.loadMemoryVariables({});
  const promptSeenByModel =
    STATIC_SYSTEM_PROMPT + "\n\n[chat_history]\n" + (vars.history || "") + "\n\n[input]\n" + text;
  const aiReply = "ردّ تجريبي " + messageText.slice(0, 6);
  await memory.saveContext({ input: text }, { output: aiReply });
  return { promptSeenByModel, aiReply };
}

// --- helper: the PROPOSED fix -------------------------------------------
// text = message_text ONLY. systemMessage = STATIC_SYSTEM_PROMPT + fresh
// family_context, computed and appended EVERY call, never memorized.
async function proposedTurn(memory, familyContext, messageText) {
  const text = messageText;
  const systemMessage =
    STATIC_SYSTEM_PROMPT + (familyContext ? "\n\n" + familyContext : "");
  const vars = await memory.loadMemoryVariables({});
  const promptSeenByModel =
    systemMessage + "\n\n[chat_history]\n" + (vars.history || "") + "\n\n[input]\n" + text;
  const aiReply = "ردّ تجريبي " + messageText.slice(0, 6);
  await memory.saveContext({ input: text }, { output: aiReply });
  return { promptSeenByModel, aiReply };
}

async function rawRows(tableName, sessionId) {
  const res = await pool.query(
    `select message from ${tableName} where session_id = $1 order by id`,
    [sessionId]
  );
  return res.rows.map((r) => r.message);
}

async function main() {
  const results = [];
  const check = (name, cond, detail) => results.push({ name, pass: !!cond, detail });

  // ===== CURRENT BEHAVIOR =====
  const curSession = "tg_current_123";
  const curHistory = historyFor(curSession, "n8n_chat_histories_current");
  await pool.query(`drop table if exists n8n_chat_histories_current`);
  const curMemory = new BufferWindowMemory({ chatHistory: curHistory, k: 10, memoryKey: "history" });

  const curTurns = [];
  for (let i = 0; i < parentMessages.length; i++) {
    curTurns.push(await currentTurn(curMemory, familyContextByTurn[i], parentMessages[i]));
  }
  const curRows = await rawRows("n8n_chat_histories_current", curSession);
  const curHumanRows = curRows.filter((m) => m.type === "human");

  check(
    "CURRENT: every stored human row begins with the system scaffolding, not the parent's raw words",
    curHumanRows.every((m) => m.content.startsWith("[ما نعرفه عن هذا البيت")),
    JSON.stringify(curHumanRows.map((m) => m.content.slice(0, 40)))
  );
  check(
    "CURRENT: turn 3's own prompt replays turn 1 and 2's scaffolding as \"what the human said\" (chat_history)",
    curTurns[2].promptSeenByModel.includes("[ما نعرفه عن هذا البيت") &&
      (curTurns[2].promptSeenByModel.match(/\[ما نعرفه عن هذا البيت/g) || []).length >= 3, // turn1 mem + turn2 mem + turn3 current input
    curTurns[2].promptSeenByModel.length + " chars, occurrences=" +
      (curTurns[2].promptSeenByModel.match(/\[ما نعرفه عن هذا البيت/g) || []).length
  );

  // ===== PROPOSED BEHAVIOR =====
  const propSession = "tg_proposed_123";
  const propHistory = historyFor(propSession, "n8n_chat_histories_proposed");
  await pool.query(`drop table if exists n8n_chat_histories_proposed`);
  const propMemory = new BufferWindowMemory({ chatHistory: propHistory, k: 10, memoryKey: "history" });

  const propTurns = [];
  for (let i = 0; i < parentMessages.length; i++) {
    propTurns.push(await proposedTurn(propMemory, familyContextByTurn[i], parentMessages[i]));
  }
  const propRows = await rawRows("n8n_chat_histories_proposed", propSession);
  const propHumanRows = propRows.filter((m) => m.type === "human");

  // Q3 proof — family_context can NEVER later appear as if the parent wrote it.
  check(
    "Q3 PROVEN: no stored human row contains the family-context marker, ever",
    propHumanRows.every((m) => !m.content.includes("[ما نعرفه عن هذا البيت")),
    JSON.stringify(propHumanRows.map((m) => m.content))
  );
  check(
    "Q3 PROVEN: stored human rows equal the raw parent messages, verbatim, nothing prepended",
    propHumanRows.map((m) => m.content).join("|") === parentMessages.join("|"),
    JSON.stringify(propHumanRows.map((m) => m.content))
  );
  check(
    "Q3 PROVEN: turn 3's replayed chat_history contains zero occurrences of the scaffolding marker",
    (propTurns[2].promptSeenByModel.match(/\[ما نعرفه عن هذا البيت/g) || []).length === 1, // only THIS turn's live systemMessage, not from history
    "occurrences=" + (propTurns[2].promptSeenByModel.match(/\[ما نعرفه عن هذا البيت/g) || []).length
  );

  // Q4 proof — nothing ADAM needs is lost: the CURRENT turn's family_context
  // (the freshest, most accurate one) still reaches the model on every turn.
  for (let i = 0; i < parentMessages.length; i++) {
    check(
      `Q4 PROVEN: turn ${i + 1}'s prompt still carries that turn's own fresh family_context`,
      propTurns[i].promptSeenByModel.includes(familyContextByTurn[i]),
      "turn " + (i + 1)
    );
  }
  // And the model still sees the real conversation history (not lost, just
  // no longer contaminated) — turn 3 must be able to see turn 1 and 2's
  // actual human words and the AI's actual prior replies.
  check(
    "Q4 PROVEN: turn 3's prompt still contains turn 1 and turn 2's raw parent messages via chat_history",
    propTurns[2].promptSeenByModel.includes(parentMessages[0]) &&
      propTurns[2].promptSeenByModel.includes(parentMessages[1]),
    "ok"
  );
  check(
    "Q4 PROVEN: turn 3's prompt still contains the prior AI replies via chat_history",
    propTurns[2].promptSeenByModel.includes(curTurns[0].aiReply.length ? propTurns[0].aiReply : "") ,
    "ok"
  );

  // Multiple consecutive messages / memory recall in a LATER message —
  // the exact two required coverage cases.
  check(
    "COVERAGE: several consecutive parent messages each stored as their own clean row",
    propHumanRows.length === 3,
    "rows=" + propHumanRows.length
  );
  check(
    "COVERAGE: memory recall in a later message — turn 3 can 'recall' yousef's name from turn 2 through chat_history, not through invented memory",
    propTurns[2].promptSeenByModel.includes("اسمه يوسف"),
    "ok"
  );

  // Ordinary message with no family_context at all (e.g. a brand-new
  // stranger, family_context = '') must not crash and must not insert an
  // empty/garbled human row.
  const bareSession = "tg_bare_1";
  const bareHistory = historyFor(bareSession, "n8n_chat_histories_bare");
  await pool.query(`drop table if exists n8n_chat_histories_bare`);
  const bareMemory = new BufferWindowMemory({ chatHistory: bareHistory, k: 10, memoryKey: "history" });
  const bareTurn = await proposedTurn(bareMemory, "", "سلام، ابني ما يهدأش");
  const bareRows = await rawRows("n8n_chat_histories_bare", bareSession);
  check(
    "COVERAGE: plain parent message, no family_context yet — stored verbatim, prompt still well-formed",
    bareRows[0].content === "سلام، ابني ما يهدأش" && bareTurn.promptSeenByModel.includes("سلام، ابني ما يهدأش"),
    JSON.stringify(bareRows[0])
  );

  // ===== report =====
  let pass = 0;
  for (const r of results) {
    console.log((r.pass ? "PASS" : "FAIL") + "  " + r.name + (r.pass ? "" : "\n      -> " + r.detail));
    if (r.pass) pass++;
  }
  console.log(`\n${pass} / ${results.length} passed`);

  await pool.end();
  process.exit(pass === results.length ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(2);
});
