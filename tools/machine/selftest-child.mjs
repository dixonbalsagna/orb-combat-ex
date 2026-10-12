// A launcher for tools/machine/selftest.mjs to kill: starts a guarded browser, prints its profile folder and waits. Not for use on its own.
import { launchBrowser } from './browser.mjs';
const b = await launchBrowser({ session: 'selftest', purpose: 'orphan', timeoutS: Number(process.env.CHILD_TIMEOUT || 300), graceS: Number(process.env.CHILD_GRACE || 180), log: () => {} });
console.log(`PROFILE ${b.profile}`);
setInterval(() => {}, 1000);
