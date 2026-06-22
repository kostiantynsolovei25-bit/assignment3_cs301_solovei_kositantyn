SELECT * FROM assignment3.orders;
SELECT * FROM assignment3.order_items;
SELECT * FROM assignment3.products;


CREATE OR REPLACE FUNCTION calculate_order_total (p_order_id INT)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
		SELECT SUM(quantity * price) FROM assignment3.order_items
		WHERE order_id = p_order_id
		GROUP BY order_id
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


SELECT calculate_order_total(1);
CALL create_order(1);

CALL add_product_to_order(3, 2, -1); -- throws error
CALL add_product_to_order(3, 2, 2);
