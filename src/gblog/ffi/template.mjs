import fs from 'node:fs'
import pug from 'pug'
import { is_prod } from './util.mjs'

const asset_mtime = (path) => {
  try {
    return fs.statSync(path).mtimeMs;
  } catch {
    return Date.now();
  }
}

const asset_version = Math.round(Math.max(
  asset_mtime('./static/css/application.css'),
  asset_mtime('./static/js/main.js'),
));

export const template = (file, vars) => {
  const data = vars?.[0] ? JSON.parse(vars[0]) : {};
  data.livereload = !is_prod();
  data.asset_version = asset_version;
  return pug.renderFile(file, data);
}
