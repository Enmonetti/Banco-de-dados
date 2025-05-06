CREATE TABLE funcionarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100),
    salario DECIMAL(10,2)
);

CREATE TABLE log_salarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    funcionario_id INT,
    salario_antigo DECIMAL(10,2),
    salario_novo DECIMAL(10,2),
    data_modificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE log_exclusoes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    funcionario_id INT,
    nome VARCHAR(100),
    salario DECIMAL(10,2),
    data_exclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE log_insercoes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    funcionario_id INT,
    nome VARCHAR(100),
    salario DECIMAL(10,2),
    data_inclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER after_salario_update
AFTER UPDATE ON funcionarios
FOR EACH ROW
BEGIN
    IF OLD.salario != NEW.salario THEN
        INSERT INTO log_salarios (funcionario_id, salario_antigo, salario_novo)
        VALUES (OLD.id, OLD.salario, NEW.salario);
    END IF;
END$$

CREATE TRIGGER after_funcionario_delete
AFTER DELETE ON funcionarios
FOR EACH ROW
BEGIN
    INSERT INTO log_exclusoes (funcionario_id, nome, salario)
    VALUES (OLD.id, OLD.nome, OLD.salario);
END$$

CREATE TRIGGER after_funcionario_insert
AFTER INSERT ON funcionarios
FOR EACH ROW
BEGIN
    INSERT INTO log_insercoes (funcionario_id, nome, salario)
    VALUES (NEW.id, NEW.nome, NEW.salario);
END$$

DELIMITER ;

-- Testes
INSERT INTO funcionarios (nome, salario) VALUES ('João', 3000.00);
UPDATE funcionarios SET salario = 3500.00 WHERE nome = 'João';
DELETE FROM funcionarios WHERE nome = 'João';
INSERT INTO funcionarios (nome, salario) VALUES ('Ana', 5000.00);

SELECT * FROM log_salarios;
SELECT * FROM log_exclusoes;
SELECT * FROM log_insercoes;
