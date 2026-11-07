import '@backstage/cli/asset-types';
import ReactDOM from 'react-dom/client';
import App from './App';
import '@backstage/ui/css/styles.css';

function ensureRandomUUID() {
  if (typeof globalThis.crypto?.randomUUID === 'function') {
    return;
  }

  const cryptoObject = globalThis.crypto;
  if (!cryptoObject?.getRandomValues) {
    throw new Error('This browser does not provide the cryptographic APIs required by Backstage');
  }

  Object.defineProperty(cryptoObject, 'randomUUID', {
    configurable: true,
    value: () => {
      const bytes = cryptoObject.getRandomValues(new Uint8Array(16));
      bytes[6] = (bytes[6] & 0x0f) | 0x40;
      bytes[8] = (bytes[8] & 0x3f) | 0x80;
      const hex = Array.from(bytes, byte => byte.toString(16).padStart(2, '0')).join('');
      return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
    },
  });
}

ensureRandomUUID();
ReactDOM.createRoot(document.getElementById('root')!).render(App.createRoot());
