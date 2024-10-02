CREATE TABLE venda_carros (
    placa VARCHAR(7) PRIMARY KEY,
    modelo_carro VARCHAR(50),
    uf CHAR(2),
    valor_carro DECIMAL(10, 2)
);
INSERT INTO venda_carros (placa, modelo_carro, uf, valor_carro) VALUES
('ABC1234', 'Corolla', 'SP', 50000.00),
('DEF5678', 'Civic', 'RJ', 75000.00),
('GHI9012', 'Gol', 'MG', 100000.00),
('JKL3456', 'Onix', 'SP', 65000.00),
('MNO7890', 'HB20', 'PR', 85000.00),
('PQR2345', 'Sandero', 'RS', 90000.00),
('STU6789', 'Uno', 'BA', 45000.00),
('VWX3456', 'Kwid', 'SC', 70000.00),
('YZA8901', 'Argo', 'ES', 55000.00),
('BCD1234', 'Renegade', 'PE', 80000.00),
('EFG5678', 'T-Cross', 'GO', 95000.00),
('HIJ9012', 'Creta', 'DF', 120000.00),
('KLM3456', 'Compass', 'TO', 65000.00),
('NOP7890', 'Strada', 'AL', 60000.00),
('QRS2345', 'HR-V', 'PB', 85000.00),
('TUV6789', 'Tracker', 'CE', 70000.00),
('WXY3456', 'Tiggo', 'AM', 50000.00),
('ZAB8901', 'Duster', 'SE', 75000.00),
('CDE1234', 'S10', 'MT', 100000.00),
('FGH5678', 'Hilux', 'PA', 45000.00);