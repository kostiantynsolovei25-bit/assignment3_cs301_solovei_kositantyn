SELECT * FROM assignment3.orders;
SELECT * FROM assignment3.order_items;
SELECT * FROM assignment3.order_log;
SELECT * FROM assignment3.products;


CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id INT)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
DECLARE
	v_total DECIMAL;
BEGIN
    RETURN (
		SELECT COALESCE(SUM(quantity * price), 0) FROM assignment3.order_items
		WHERE order_id = p_order_id
	);
END;
$$;


CREATE OR REPLACE PROCEDURE create_order(p_customer_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
	IF EXISTS (SELECT 1 FROM assignment3.orders WHERE customer_id = p_customer_id) THEN
        INSERT INTO assignment3.orders(customer_id, order_date, total_amount)
   		VALUES (p_customer_id, NOW(), 0.0);
    END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE add_product_to_order(p_order_id INT, p_product_id INT, p_quantity INT)
LANGUAGE plpgsql
AS $$
DECLARE
	v_price NUMERIC;
    v_stock INT;
BEGIN
	IF NOT EXISTS (SELECT 1 FROM assignment3.orders WHERE order_id = p_order_id) THEN
		RAISE NOTICE 'Invalid order_id';
        RETURN; 
	END IF;
	
	IF NOT EXISTS (SELECT 1 FROM assignment3.products WHERE product_id = p_product_id) THEN
		RAISE NOTICE 'Invalid product_id';
        RETURN; 
	END IF;


	SELECT price, stock_quantity 
    INTO v_price, v_stock
    FROM assignment3.products 
    WHERE product_id = p_product_id;
	
	IF p_quantity <= 0 OR v_stock < p_quantity THEN
		RAISE NOTICE 'Invalid quantity';
        RETURN; 
	END IF;
	
	INSERT INTO assignment3.order_items(order_id, product_id, quantity, price)
	VALUES (p_order_id, p_product_id, p_quantity, v_price);

	UPDATE assignment3.products 
	SET stock_quantity = stock_quantity - p_quantity
	WHERE product_id = p_product_id;
END;
$$;


CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    v_order_id := COALESCE(NEW.order_id, OLD.order_id);

    UPDATE assignment3.orders
    SET total_amount = assignment3.calculate_order_total(v_order_id)
    WHERE order_id = v_order_id;

    RETURN NULL;
END;
$$;


CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    v_order_id := COALESCE(NEW.order_id, OLD.order_id);

    UPDATE assignment3.orders
    SET total_amount = assignment3.calculate_order_total(v_order_id)
    WHERE order_id = v_order_id;

    RETURN NULL;
END;
$$;


CREATE OR REPLACE TRIGGER trigger_update_total_amount
AFTER INSERT OR UPDATE OR DELETE
ON assignment3.order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();


CREATE OR REPLACE FUNCTION create_order_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
    INSERT INTO assignment3.order_log (order_id, customer_id, action_type, log_timestamp)
    VALUES (NEW.order_id, NEW.customer_id, 'ordered', NOW());
	RETURN NULL;
END;
$$;


CREATE OR REPLACE TRIGGER add_order_to_log
AFTER INSERT
ON assignment3.orders
FOR EACH ROW
EXECUTE FUNCTION create_order_log();



SELECT calculate_order_total(1);
CALL create_order(1);

CALL add_product_to_order(3, 2, -1); -- throws error
CALL add_product_to_order(3, 2, 2);
