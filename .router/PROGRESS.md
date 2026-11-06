# PROGRESS
| task | state | notes |
|---|---|---|
| tables | done | challenge_plan SFTJDedNFuDUVxYI, challenge_control lUH1zXDiNTWX0k0b, challenge_inbox Yl5TIRDzbwUokL4W, challenge_checkins AEqEYVGrw4hrbrev, challenge_actions UhVkwqKZ3Vy2R9tf, join_queue 4odqp9Pu0Z0VJZvl, wapito_poll_votes D8ZfSYKpaKrj4qOJ |
| gateway | done, published | n24t1p7539gVUtyC — creds must be picked in UI (Wapito API + Telegram Founder) |
| review page | done, published | 7A0rTMpcivvZfiyG GET /webhook/adam-review?t=<review_token>, POST /webhook/adam-review-save. TODO cosmetic: render/done wording gender-neutral (files in scratchpad n8n/) |
| scheduler | done, published | XJUnDnn9wsoa17lG every 5 min; only status=approved; jitter -7..+8; >3h late -> missed |
| week-1 rows | loaded (draft) | 17 rows; times 08:30 / 20:00 UTC (poll winner: after kids sleep; 2nd after school) |
| voices | 7/9 | v6, v8 pending (ElevenLabs busy) |
| admin read | util | eUTQf91dchqn4BPP (Table node id) |
| group brain | next | events wf HVhsXj0qsVw2DLir to extend; LLM via gateway op=llm (OpenRouter cred) |
| Wapito webhooks | 1 only | ours ("*"). No DM responder on WhatsApp -> ask founder |
| events wf | extended, published | HVhsXj0qsVw2DLir: inbox, ✅ check-ins (+heart react), join_queue |
| brain | built, published, OFF | XAmtgzVVM0wfntpf cron 17 7-23/2 UTC; control brain_on=false until creds bound |
| control | published | lmbbSSGeegWGznvl GET /webhook/adam-control?t=&k=paused|brain_on|join_window&v= |
| gateway | +LLM branch | op=llm -> OpenRouter (cred openRouterApi to pick in UI) |
| voices | 8/9 | v8 text-only: ElevenLabs free tier disabled ("unusual activity") -> founder must upgrade for future weeks |
| next | todo | certificate PNG route + finisher DM gift; join approvals (needs Nour admin); channel plan + shorts (Vercel sandbox); WhatsApp DM responder question |
| voices | 9/9 | v8 generated (22s), voices/w1-v8.mp3, row w1-d8-am now voice+text; all 17 rows approved |
| card | done | academic «بطاقة تهنئة» via adam-card (Amiri title, Thmanyah Serif, wax seal); desk takes «بطاقتي name - child», 3x retry on cold start |
| cleanup | done | archived TEMP JOffxbOlSUZsGPjz + j5hH2PPtSsOI0cZM; admin read Summary restored. Left alone: P21 Whop Probe lmyoIrhsikIal15d (older session), Wapito test anDsaXXmBU9EZUbJ (founder's) |
| next | todo | WhatsApp DM brain for Nour (task 13); channel shorts + weekly plan (task 12); dashboard KPIs |
