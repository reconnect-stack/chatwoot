import '../design-system/stories.scss';
import { createI18n } from 'vue-i18n';
import { createRouter, createMemoryHistory } from 'vue-router';
import { vResizeObserver } from '@vueuse/components';
import FloatingVue from 'floating-vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { directive as onClickaway } from 'vue3-click-away';
import dashboardI18n from 'dashboard/i18n';
import widgetI18n from 'widget/i18n';
import store from 'dashboard/store';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer.js';

// A throwaway router so composables like useRoute()/useAccount() resolve a real
// route object instead of throwing. We seed realistic Help Center params
// (accountId/portalSlug/locale) so page-level stories that key off the route
// render instead of bailing out. Story selection itself is hash-based and
// independent of this router.
const noop = { render: () => null };
const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    {
      path: '/app/accounts/:accountId/portals/:portalSlug/:locale?',
      name: 'stories',
      component: noop,
    },
    { path: '/:pathMatch(.*)*', name: 'fallback', component: noop },
  ],
});
router.replace('/app/accounts/1/portals/chatwoot/en');

function mergeMessages(...sources) {
  return sources.reduce((acc, src) => {
    Object.keys(src).forEach(key => {
      if (
        acc[key] &&
        typeof acc[key] === 'object' &&
        typeof src[key] === 'object'
      ) {
        acc[key] = mergeMessages(acc[key], src[key]);
      } else {
        acc[key] = src[key];
      }
    });
    return acc;
  }, {});
}

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: mergeMessages(
    structuredClone(dashboardI18n),
    structuredClone(widgetI18n)
  ),
});

// Registers the same global plugins/directives the dashboard components expect
// at runtime, so stories render identically to the real app.
export function setupApp(app) {
  app.use(store);
  app.use(i18n);
  app.use(router);
  app.use(FloatingVue, {
    instantMove: true,
    arrowOverflow: false,
    disposeTimeout: 5000000,
  });

  app.directive('resize', vResizeObserver);
  app.use(VueDOMPurifyHTML, domPurifyConfig);
  app.directive('on-clickaway', onClickaway);
}
