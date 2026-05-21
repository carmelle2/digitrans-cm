-- ERP Seed Data (Cameroon context)
INSERT IGNORE INTO employees (full_name, email, role, department, salary, hire_date, status) VALUES
('Jean-Pierre Mbarga', 'jp.mbarga@agrocam.cm', 'ROLE_MANAGER', 'Operations', 850000.00, '2020-03-15', 'ACTIVE'),
('Aissatou Nkemdirim', 'a.nkemdirim@agrocam.cm', 'ROLE_AGENT', 'Supply Chain', 450000.00, '2021-06-01', 'ACTIVE'),
('Paul Biya Fotso', 'p.fotso@agrocam.cm', 'ROLE_ADMIN', 'IT', 950000.00, '2019-01-10', 'ACTIVE'),
('Marie-Claire Essomba', 'mc.essomba@agrocam.cm', 'ROLE_AGENT', 'CRM', 420000.00, '2022-09-20', 'ACTIVE'),
('Thierry Kamga', 't.kamga@agrocam.cm', 'ROLE_VIEWER', 'Finance', 380000.00, '2023-02-14', 'ACTIVE');

INSERT IGNORE INTO suppliers (name, contact, country, contract_start, contract_end) VALUES
('Cacao Export Cameroun', '+237 699 001 001', 'Cameroun', '2023-01-01', '2025-12-31'),
('Café du Moungo SARL', '+237 677 002 002', 'Cameroun', '2022-06-01', '2024-05-31'),
('AgroTrans Logistics', '+237 655 003 003', 'Cameroun', '2023-03-15', '2026-03-14');

INSERT IGNORE INTO accounting_entries (label, amount, currency, type, date, reference) VALUES
('Vente cacao - Lot 001', 12500000.00, 'XAF', 'CREDIT', '2024-01-15', 'REF-2024-001'),
('Frais transport Douala-Yaoundé', 350000.00, 'XAF', 'DEBIT', '2024-01-20', 'REF-2024-002'),
('Salaires Janvier 2024', 3050000.00, 'XAF', 'DEBIT', '2024-01-31', 'REF-2024-003');
