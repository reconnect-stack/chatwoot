import { createCacheRevalidateAction } from '../cacheRevalidate';

describe('#createCacheRevalidateAction', () => {
  const commit = vi.fn();

  beforeEach(() => {
    commit.mockReset();
  });

  it('refetches and commits data when the cache key is stale', async () => {
    const api = {
      validateCacheKey: vi.fn().mockResolvedValue(false),
      refetchAndCommit: vi.fn().mockResolvedValue({ data: [{ id: 1 }] }),
    };

    const action = createCacheRevalidateAction({
      api,
      mutation: 'SET_RECORDS',
    });

    await action({ commit }, { newKey: 'new-key' });

    expect(api.validateCacheKey).toHaveBeenCalledWith('new-key');
    expect(api.refetchAndCommit).toHaveBeenCalledWith('new-key');
    expect(commit).toHaveBeenCalledWith('SET_RECORDS', [{ id: 1 }]);
  });

  it('skips refetch when the cache key is current', async () => {
    const api = {
      validateCacheKey: vi.fn().mockResolvedValue(true),
      refetchAndCommit: vi.fn(),
    };

    const action = createCacheRevalidateAction({
      api,
      mutation: 'SET_RECORDS',
    });

    await action({ commit }, { newKey: 'new-key' });

    expect(api.refetchAndCommit).not.toHaveBeenCalled();
    expect(commit).not.toHaveBeenCalled();
  });

  it('supports clear-before-set and custom response data extraction', async () => {
    const api = {
      validateCacheKey: vi.fn().mockResolvedValue(false),
      refetchAndCommit: vi
        .fn()
        .mockResolvedValue({ data: { payload: [{ id: 1 }] } }),
    };

    const action = createCacheRevalidateAction({
      api,
      mutation: 'SET_RECORDS',
      clearMutation: 'CLEAR_RECORDS',
      getData: response => response.data.payload,
    });

    await action({ commit }, { newKey: 'new-key' });

    expect(commit.mock.calls).toEqual([
      ['CLEAR_RECORDS'],
      ['SET_RECORDS', [{ id: 1 }]],
    ]);
  });

  it('ignores revalidation errors', async () => {
    const api = {
      validateCacheKey: vi.fn().mockRejectedValue(new Error('boom')),
      refetchAndCommit: vi.fn(),
    };

    const action = createCacheRevalidateAction({
      api,
      mutation: 'SET_RECORDS',
    });

    await expect(action({ commit }, { newKey: 'new-key' })).resolves.toBe();
    expect(commit).not.toHaveBeenCalled();
  });
});
