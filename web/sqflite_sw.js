// SQLite Service Worker for Web
// This file is required by sqflite_common_ffi_web

importScripts('https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js');

let db;

self.addEventListener('message', async (event) => {
  const { id, method, args } = event.data;
  
  try {
    let result;
    
    switch (method) {
      case 'init':
        const SQL = await initSqlJs({
          locateFile: file => `https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/${file}`
        });
        db = new SQL.Database();
        result = { success: true };
        break;
        
      case 'execute':
        if (!db) throw new Error('Database not initialized');
        db.run(args[0]);
        result = { success: true };
        break;
        
      case 'query':
        if (!db) throw new Error('Database not initialized');
        const queryResult = db.exec(args[0]);
        result = { success: true, data: queryResult };
        break;
        
      default:
        throw new Error(`Unknown method: ${method}`);
    }
    
    self.postMessage({ id, result });
  } catch (error) {
    self.postMessage({ id, error: error.message });
  }
});
