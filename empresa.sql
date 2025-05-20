CREATE DATABASE IndustriaDB;
USE IndustriaDB;

CREATE TABLE Funcionarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cargo VARCHAR(50),
    data_admissao DATE,
    data_demissao DATE
);

CREATE TABLE Produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL
);

CREATE TABLE Producao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT NOT NULL,
    funcionario_id INT NOT NULL,
    quantidade INT NOT NULL,
    data_producao DATE NOT NULL,
    FOREIGN KEY (produto_id) REFERENCES Produtos(id),
    FOREIGN KEY (funcionario_id) REFERENCES Funcionarios(id)
);

CREATE TABLE Estoque (
    produto_id INT PRIMARY KEY,
    quantidade INT NOT NULL DEFAULT 0,
    FOREIGN KEY (produto_id) REFERENCES Produtos(id)
);

CREATE VIEW View_EstoqueDetalhado AS
SELECT
    p.nome AS nome_produto,
    e.quantidade
FROM Estoque e
JOIN Produtos p ON e.produto_id = p.id;

DELIMITER //
CREATE FUNCTION CalcularValorEstoque()
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(15,2);
    SELECT SUM(p.preco_unitario * e.quantidade)
    INTO total
    FROM Produtos p
    JOIN Estoque e ON p.id = e.produto_id;
    RETURN IFNULL(total, 0.00);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE RegistrarProducao(
    IN p_produto_id INT,
    IN p_funcionario_id INT,
    IN p_quantidade INT
)
BEGIN
    INSERT INTO Producao (produto_id, funcionario_id, quantidade, data_producao)
    VALUES (p_produto_id, p_funcionario_id, p_quantidade, CURDATE());

    UPDATE Estoque
    SET quantidade = quantidade + p_quantidade
    WHERE produto_id = p_produto_id;

    INSERT INTO Estoque (produto_id, quantidade)
    SELECT p_produto_id, p_quantidade
    WHERE NOT EXISTS (
        SELECT 1 FROM Estoque WHERE produto_id = p_produto_id
    );
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER AtualizarEstoqueAposProducao
AFTER INSERT ON Producao
FOR EACH ROW
BEGIN
    UPDATE Estoque
    SET quantidade = quantidade + NEW.quantidade
    WHERE produto_id = NEW.produto_id;

    INSERT INTO Estoque (produto_id, quantidade)
    SELECT NEW.produto_id, NEW.quantidade
    WHERE NOT EXISTS (
        SELECT 1 FROM Estoque WHERE produto_id = NEW.produto_id
    );
END //
DELIMITER ;

INSERT INTO Funcionarios (nome, cargo, data_admissao)
VALUES
('Ana Souza', 'Operadora de Máquinas', '2023-01-10'),
('Carlos Lima', 'Supervisor de Produção', '2022-03-15');

INSERT INTO Produtos (nome, preco_unitario)
VALUES
('Parafuso A', 0.50),
('Peça B', 2.75);

INSERT INTO Estoque (produto_id, quantidade)
VALUES (1, 100), (2, 50);

CALL RegistrarProducao(1, 1, 20);
CALL RegistrarProducao(2, 2, 30);
