import { getStore } from '@netlify/blobs';

const STORE_NAME = 'smart-lista';
const LIST_KEY = 'shared-list';
const INITIAL_ITEM_DATE = '1970-01-01T00:00:00.000Z';
const jsonHeaders = {
  'Content-Type': 'application/json',
  'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0'
};

function jsonResponse(body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {...jsonHeaders, ...extraHeaders}
  });
}

function itemKey(item) {
  return (item.id || `${item.cat}::${item.name}`).toLowerCase();
}

function createItemId(cat,name) {
  return `${cat}::${name}`.trim().toLowerCase();
}

function normalizeItem(item) {
  const qty = Number(item.qty ?? 1);

  return {
    ...item,
    id: item.id || createItemId(item.cat,item.name),
    qty: Math.max(0, qty),
    deleted: Boolean(item.deleted),
    updatedAt: item.updatedAt || INITIAL_ITEM_DATE
  };
}

function mergeItems(currentItems = [], incomingItems = []) {
  currentItems = currentItems || [];
  incomingItems = incomingItems || [];

  const mergedByKey = new Map();

  currentItems.map(normalizeItem).forEach((item) => {
    mergedByKey.set(itemKey(item), item);
  });

  incomingItems.map(normalizeItem).forEach((incomingItem) => {
    const currentItem = mergedByKey.get(itemKey(incomingItem));

    if (!currentItem) {
      mergedByKey.set(itemKey(incomingItem), incomingItem);
      return;
    }

    const incomingUpdatedAt = Date.parse(incomingItem.updatedAt || INITIAL_ITEM_DATE);
    const currentUpdatedAt = Date.parse(currentItem.updatedAt || INITIAL_ITEM_DATE);

    if (incomingUpdatedAt >= currentUpdatedAt) {
      mergedByKey.set(itemKey(incomingItem), incomingItem);
    }
  });

  return Array.from(mergedByKey.values());
}

export default async function syncList(request) {
  try {
    const store = getStore(STORE_NAME);

    if (request.method === 'GET') {
      const savedList = await store.get(LIST_KEY, { type: 'json' });
      return jsonResponse(savedList || { items: [], updatedAt: null });
    }

    if (request.method === 'POST') {
      const payload = await request.json().catch(() => ({}));

      if (!Array.isArray(payload.items)) {
        return jsonResponse({ error: 'items must be an array' }, 400);
      }

      const currentList = await store.get(LIST_KEY, { type: 'json' });
      const savedList = {
        items: mergeItems(currentList && currentList.items, payload.items),
        updatedAt: new Date().toISOString()
      };

      await store.setJSON(LIST_KEY, savedList);
      return jsonResponse({ ok: true, updatedAt: savedList.updatedAt });
    }

    return jsonResponse(
      { error: 'method not allowed' },
      405,
      { Allow: 'GET, POST' }
    );
  } catch (error) {
    return jsonResponse({ error: error.message || 'sync failed' }, 500);
  }
}
