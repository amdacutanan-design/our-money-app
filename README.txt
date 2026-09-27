MALAMA JOURNEY V4.1

1. In Supabase SQL Editor, run stability-migration.sql once.
2. In GitHub, replace index.html and sw.js with the files in this folder.
3. Open the live app with a cache-busting query, e.g. ?v=41.
4. On EACH iPhone, open More > Card reminders and tap Enable reminders on this device.

V4.1 audit fixes:
- property payment_due_day schema mismatch
- preserves original debt balance when editing a card/loan
- adds card reminder settings and due-soon alerts
- adds payment method/account/notes to transactions
- adds Investment contribution transaction type and Stocks / Investments category
- keeps transaction/property/debt edit/delete and monthly reports

Note: iPhone web notifications from a PWA are most reliable after adding the app to the Home Screen. This build checks deadlines whenever the app opens, syncs, or returns to the foreground. Guaranteed notifications while the app is completely closed require a server-side Web Push service, which is not included yet.
