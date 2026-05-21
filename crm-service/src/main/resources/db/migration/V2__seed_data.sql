-- CRM Seed Data (Cameroon context)
INSERT IGNORE INTO restaurants (name, city, address, manager_name, is_active) VALUES
('AGROCAM Restaurant Douala', 'Douala', 'Rue de la Joie, Akwa, Douala', 'Rodrigue Tchamba', 1),
('AGROCAM Restaurant Yaoundé', 'Yaoundé', 'Avenue Kennedy, Centre-ville, Yaoundé', 'Solange Mekongo', 1),
('AGROCAM Restaurant Bafoussam', 'Bafoussam', 'Marché B, Bafoussam', 'Hervé Nkouatchet', 1);

INSERT IGNORE INTO customers (name, email, phone, city, loyalty_points) VALUES
('Christophe Atangana', 'c.atangana@gmail.com', '+237 691 100 001', 'Yaoundé', 150),
('Fatima Oumarou', 'f.oumarou@yahoo.fr', '+237 677 200 002', 'Douala', 80),
('Bertrand Nkolo', 'b.nkolo@hotmail.com', '+237 655 300 003', 'Bafoussam', 220);

INSERT IGNORE INTO orders (customer_id, restaurant_branch, items, total_amount, status) VALUES
(1, 'AGROCAM Restaurant Yaoundé', '[{"name":"Ndolé","qty":2,"price":3500},{"name":"Jus de Bissap","qty":2,"price":500}]', 8000.00, 'DELIVERED'),
(2, 'AGROCAM Restaurant Douala', '[{"name":"Poulet DG","qty":1,"price":5000}]', 5000.00, 'CONFIRMED'),
(3, 'AGROCAM Restaurant Bafoussam', '[{"name":"Eru","qty":1,"price":2500},{"name":"Eau minérale","qty":1,"price":300}]', 2800.00, 'PENDING');
