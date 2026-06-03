import { createApp } from 'vue';
import App from './App.vue';
import Story from './Story.vue';
import Variant from './Variant.vue';
import { setupApp } from './setup';

const app = createApp(App);

// Story files reference <Story> and <Variant> as globals (same as Histoire).
app.component('Story', Story);
app.component('Variant', Variant);

setupApp(app);

app.mount('#app');
