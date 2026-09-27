# Mālama Journey V3

This build adds Supabase sign-in, household creation/joining, and shared cloud sync for transactions, savings goals, properties, investments, debts and budgets.

## Before uploading
Run `supabase-migration.sql` once in Supabase SQL Editor. It adds the synced budgets table and enables realtime for the app tables.

Then replace the existing GitHub Pages files with `index.html`, `manifest.json`, and `sw.js`.
