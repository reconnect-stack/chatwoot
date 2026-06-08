export const createCacheRevalidateAction =
  ({ api, mutation, clearMutation, getData = response => response.data }) =>
  async ({ commit }, { newKey }) => {
    try {
      const isExistingKeyValid = await api.validateCacheKey(newKey);
      if (isExistingKeyValid) return;

      const response = await api.refetchAndCommit(newKey);
      if (clearMutation) commit(clearMutation);
      commit(mutation, getData(response));
    } catch (error) {
      // Ignore error
    }
  };
