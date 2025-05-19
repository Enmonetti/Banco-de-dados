
-- Banco de Dados: Armazenagem_Eficiente
CREATE DATABASE IF NOT EXISTS Armazenagem_Eficiente;
USE Armazenagem_Eficiente;

-- Tabela: Armazenamento
CREATE TABLE IF NOT EXISTS Armazenamento (
    id_armazenamento INT PRIMARY KEY AUTO_INCREMENT,
    capacidade_total INT NOT NULL,
    capacidade_utilizada INT DEFAULT 0
);

-- Tabela: Fornecedor
CREATE TABLE IF NOT EXISTS Fornecedor (
    id_fornecedor INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    contato VARCHAR(100)
);

-- Tabela: Produto
CREATE TABLE IF NOT EXISTS Produto (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(255) NOT NULL,
    quantidade_estoque INT DEFAULT 0,
    id_armazenamento INT,
    id_fornecedor INT,
    FOREIGN KEY (id_armazenamento) REFERENCES Armazenamento(id_armazenamento),
    FOREIGN KEY (id_fornecedor) REFERENCES Fornecedor(id_fornecedor)
);

-- Tabela: Transportadora
CREATE TABLE IF NOT EXISTS Transportadora (
    id_transportadora INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    contato VARCHAR(100)
);

-- Tabela: Pedido
CREATE TABLE IF NOT EXISTS Pedido (
    id_pedido INT PRIMARY KEY AUTO_INCREMENT,
    data_pedido DATE NOT NULL,
    status ENUM('Pendente', 'Processando', 'Enviado', 'Entregue') DEFAULT 'Pendente',
    id_transportadora INT,
    FOREIGN KEY (id_transportadora) REFERENCES Transportadora(id_transportadora)
);

-- Tabela: Pedido_Produto (N:N)
CREATE TABLE IF NOT EXISTS Pedido_Produto (
    id_pedido INT,
    id_produto INT,
    quantidade INT,
    PRIMARY KEY (id_pedido, id_produto),
    FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido),
    FOREIGN KEY (id_produto) REFERENCES Produto(id_produto)
);

-- Procedimento: Atualizar estoque após pedido
DELIMITER $$
CREATE PROCEDURE AtualizarEstoquePedido(IN pedido_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE pid INT;
    DECLARE qtd INT;
    DECLARE cur CURSOR FOR 
        SELECT id_produto, quantidade FROM Pedido_Produto WHERE id_pedido = pedido_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO pid, qtd;
        IF done THEN
            LEAVE read_loop;
        END IF;
        UPDATE Produto
        SET quantidade_estoque = quantidade_estoque - qtd
        WHERE id_produto = pid;
    END LOOP;
    CLOSE cur;
END$$
DELIMITER ;

-- Procedimento: Alocar produto em armazenamento
DELIMITER $$
CREATE PROCEDURE AlocarProduto(IN produto_id INT, IN qtd INT)
BEGIN
    DECLARE armazenamento_id INT;

    SELECT id_armazenamento INTO armazenamento_id
    FROM Armazenamento
    WHERE capacidade_total - capacidade_utilizada >= qtd
    ORDER BY capacidade_total - capacidade_utilizada DESC
    LIMIT 1;

    IF armazenamento_id IS NOT NULL THEN
        UPDATE Produto
        SET id_armazenamento = armazenamento_id
        WHERE id_produto = produto_id;

        UPDATE Armazenamento
        SET capacidade_utilizada = capacidade_utilizada + qtd
        WHERE id_armazenamento = armazenamento_id;
    END IF;
END$$
DELIMITER ;

-- Exemplo de criação de usuário com permissões limitadas
-- CREATE USER 'operador'@'localhost' IDENTIFIED BY 'senha123';
-- GRANT SELECT ON Armazenagem_Eficiente.Produto TO 'operador'@'localhost';

-- Backup sugerido via terminal (fora do SQL)
-- mysqldump -u root -p Armazenagem_Eficiente > backup_diario.sql
