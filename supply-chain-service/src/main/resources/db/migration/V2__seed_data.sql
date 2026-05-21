-- Supply Chain Seed Data (Cameroon context)
INSERT IGNORE INTO products (name, category, origin, unit, current_stock) VALUES
('Cacao Brut Grade A', 'CACAO', 'Région du Centre, Cameroun', 'Tonne', 450),
('Café Arabica Moungo', 'COFFEE', 'Région du Littoral, Cameroun', 'Tonne', 120),
('Produits Alimentaires Mixtes', 'FOOD', 'Douala, Cameroun', 'Carton', 800);

INSERT IGNORE INTO shipments (product_id, origin, destination, quantity, status, departure_date, arrival_date, tracking_code) VALUES
(1, 'Yaoundé - Entrepôt Central', 'Port de Douala', 50, 'IN_TRANSIT', '2024-01-10', '2024-01-15', 'AGR-2024-001'),
(2, 'Nkongsamba - Entrepôt Moungo', 'Douala - Restaurant Central', 10, 'DELIVERED', '2024-01-05', '2024-01-08', 'AGR-2024-002');

INSERT IGNORE INTO checkpoints (shipment_id, location, timestamp, agent_name, note) VALUES
(1, 'Péage de Mbankomo', '2024-01-10 09:30:00', 'Aissatou Nkemdirim', 'Départ confirmé, marchandise en bon état'),
(1, 'Edéa - Contrôle routier', '2024-01-11 14:00:00', 'Aissatou Nkemdirim', 'Passage contrôle sanitaire OK'),
(2, 'Nkongsamba - Départ', '2024-01-05 07:00:00', 'Thierry Kamga', 'Chargement terminé'),
(2, 'Douala - Livraison', '2024-01-08 11:30:00', 'Thierry Kamga', 'Livraison effectuée avec succès');
