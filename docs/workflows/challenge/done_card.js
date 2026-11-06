// Records the card as delivered once the image went out; otherwise she can ask again with «بطاقتي».
const d = $('Decide').first().json;
const sent = $input.all().map(i => i.json);
const img = sent[0] || {};
return [{ json: { ...d.cardRow, state: img.ok ? 'done' : 'awaiting_name', card_url: (img.ok && $('Card Send').first().json._card_url) || '', updated: new Date().toISOString() } }];
