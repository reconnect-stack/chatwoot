import { cacheableModels } from './cacheableModels';

export const dispatchCacheRevalidations = (store, keys = {}) =>
  Promise.all(
    cacheableModels
      .filter(model => keys[model.name] !== undefined)
      .map(model =>
        store.dispatch(model.dispatchPath, { newKey: keys[model.name] })
      )
  );
