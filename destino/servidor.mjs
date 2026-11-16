// Sirve cada entorno en /<slug>/ con la versión a la que apunta /srv/entornos/<slug>/actual.
// El módulo de cada versión se importa por su ruta real, que lleva el SHA: una versión
// nueva es un módulo nuevo, y volver a una anterior reutiliza el que ya estaba cargado.
import http from 'node:http';
import { readFile, readdir, realpath } from 'node:fs/promises';

const RAIZ = '/srv/entornos';
const json = (res, codigo, cuerpo) => {
  res.writeHead(codigo, { 'content-type': 'application/json' });
  res.end(JSON.stringify(cuerpo) + '\n');
};

http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://destino');
  const [, slug = '', ...resto] = url.pathname.split('/');
  try {
    if (slug === '') {
      const entornos = {};
      for (const s of await readdir(RAIZ)) {
        try { entornos[s] = JSON.parse(await readFile(`${RAIZ}/${s}/actual/despliegue.json`, 'utf8')); } catch {}
      }
      return json(res, 200, entornos);
    }
    if (!/^[a-z0-9-]+$/.test(slug)) return json(res, 404, { error: 'entorno no válido' });
    const dir = await realpath(`${RAIZ}/${slug}/actual`).catch(() => null);
    if (!dir) return json(res, 404, { error: `no hay nada desplegado en ${slug}` });
    const despliegue = JSON.parse(await readFile(`${dir}/despliegue.json`, 'utf8'));
    const { default: atender } = await import(`${dir}/src/http.ts`);
    await atender(req, res, { ...despliegue, ruta: '/' + resto.join('/'), url });
  } catch (error) {
    console.error(slug, error);
    if (!res.headersSent) json(res, 500, { error: String(error.message ?? error) });
  }
}).listen(8080, () => console.log('destino escuchando en :8080'));
