import { dispatchCacheRevalidations } from '../../CacheHelper/dispatchCacheRevalidations';

describe('dispatchCacheRevalidations', () => {
  it('dispatches revalidate actions for cacheable models present in the key payload', async () => {
    const store = {
      dispatch: vi.fn().mockResolvedValue(),
    };

    await dispatchCacheRevalidations(store, {
      inbox: 'inbox-key',
      label: 'label-key',
      canned_response: 'canned-key',
      unknown_model: 'ignored-key',
    });

    expect(store.dispatch).toHaveBeenCalledWith('inboxes/revalidate', {
      newKey: 'inbox-key',
    });
    expect(store.dispatch).toHaveBeenCalledWith('labels/revalidate', {
      newKey: 'label-key',
    });
    expect(store.dispatch).toHaveBeenCalledWith('revalidateCannedResponses', {
      newKey: 'canned-key',
    });
    expect(store.dispatch).toHaveBeenCalledTimes(3);
  });

  it('treats missing keys as an empty payload', async () => {
    const store = {
      dispatch: vi.fn(),
    };

    await dispatchCacheRevalidations(store);

    expect(store.dispatch).not.toHaveBeenCalled();
  });
});
