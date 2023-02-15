USE H_Accounting;


DELIMITER $$

CREATE PROCEDURE H_Accounting.Dessert12_maint1(IN p_year INT(4), IN p_company_id INT) -- we have to name this later!!
    
			READS SQL DATA
	BEGIN

/* In order to calculate the P&L statement, we first joined all tables and sumed the debit entries up, 
in order to later filter it by year and company_id, as well retrieving the total revenue by getting REV (revenue) and IO (Other Income) 
Then we subtracted the 2nd subquery (Expenses) from the first one (Profit) and Aliased it AS profit_loss_statement, so the
result gets such heading. 
*/

SELECT 
-- Subqueries in select 
-- P&L starts here:
	CONCAT('$',FORMAT((SELECT SUM(jeli.debit) -- The "CONCAT('$',FORMAT((SELECT..." allows us to add the dollar symbol to this query's result 
										FROM account AS a
										JOIN statement_section AS st
										ON a.profit_loss_section_id = st.statement_section_id
										JOIN journal_entry_line_item AS jeli
										ON a.account_id = jeli.account_id
										JOIN journal_entry AS je
										ON jeli.journal_entry_id = je.journal_entry_id
										WHERE EXTRACT(YEAR FROM je.entry_date) = p_year -- The EXTRACT function gets us the year selected through p_year, making it possible for the code to run with any year inputed
										AND a.company_id = p_company_id  -- p_company_id allows us to keep the code working for any of the company_id 
										AND (st.statement_section_code = 'REV' OR st.statement_section_code = 'OI'))	-- Total revenue of 2018 (Revenue OR Other Income)
										-                              -- Subtracting Revenue from Expenses, to get P&L
										(SELECT SUM(jeli.debit) -- We sum debit to get the total 
										FROM account AS a
										JOIN statement_section AS st
										ON a.profit_loss_section_id = st.statement_section_id
										JOIN journal_entry_line_item AS jeli
										ON a.account_id = jeli.account_id
										JOIN journal_entry AS je
										ON jeli.journal_entry_id = je.journal_entry_id
										WHERE EXTRACT(YEAR FROM je.entry_date) = p_year -- The EXTRACT function gets us the year selected through p_year, making it possible for the code to run with year inputed
										AND a.company_id = p_company_id   -- Allows us, keep the query working after inputting any available company ID
										AND (st.statement_section_code = 'COGS' OR st.statement_section_code = 'SEXP' OR st.statement_section_code = 'OEXP' OR st.statement_section_code = 'INCTAX') -- Total costs of the year (COGS, SEXP, OEXP, INCTAX*). *Tax is also treated as expense in P&L
									), 2))-- FORMATING the data in the us currency with 2 decimal places
	AS profit_loss_statement,
    
/* 
Knowing the Balance Sheet formula is: Assets = Liabilities + Equity, we have applied this here by using the previous subquery 
to make sure we filter the results by the year and company_id selected. Then the value of all the kinds of Assets available are added together,
making this subquery equal to the SUM of liabilities and equity (following the same structure and process). 
*/

  -- Balance Sheet starts here:  
  
    CONCAT('$',FORMAT((SELECT (SUM(jeli.debit) - SUM(jeli.credit)) 
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year -- The EXTRACT function gets us the year selected through p_year, making it possible for the code to run with year inputed
			AND a.company_id = p_company_id -- p_company_id allows us to keep the code working for any of the company_id 
            AND (st.statement_section_code = 'CA' OR st.statement_section_code = 'FA' OR st.statement_section_code = 'DA'))	-- Total assets of 2018 (current assets, fixed assets, deferred assets)
           , 2)) -- FORMATING the data in the us currency with 2 decimal places
	AS balance_sheet,
	
    CASE WHEN((SELECT ROUND(SUM(jeli.debit) - SUM(jeli.credit), 2) -- This CASE statement, checks if balance_sheet query above is true or false.  
					FROM account AS a
					JOIN statement_section AS st
					ON a.balance_sheet_section_id = st.statement_section_id
					JOIN journal_entry_line_item AS jeli
					ON a.account_id = jeli.account_id
					JOIN journal_entry AS je
					ON jeli.journal_entry_id = je.journal_entry_id
					WHERE EXTRACT(YEAR FROM je.entry_date) = p_year -- The EXTRACT function gets us the year selected through p_year, making it possible for the code to run with year inputed
					AND a.company_id = p_company_id -- p_company_id allows us to keep the code working for any of the company_id 
                    AND (st.statement_section_code = 'CA' OR st.statement_section_code = 'FA' OR st.statement_section_code = 'DA'))	-- Total assets of the year
				   
                   ) =               -- Applying the Balance Sheet formula (Assets = Liabilities + Equity)
                   
                   (SELECT ROUND(SUM(jeli.credit) - SUM(jeli.debit), 2) 
					FROM account AS a
					JOIN statement_section AS st
					ON a.balance_sheet_section_id = st.statement_section_id
					JOIN journal_entry_line_item AS jeli
					ON a.account_id = jeli.account_id
					JOIN journal_entry AS je
					ON jeli.journal_entry_id = je.journal_entry_id
					WHERE EXTRACT(YEAR FROM je.entry_date) = p_year  -- The EXTRACT function gets us the year selected through p_year, making it possible for the code to run with year inputed
                    AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
					AND (st.statement_section_code = 'CL' OR st.statement_section_code = 'EQ')) -- Total L + E of the year
				THEN 'A = L + E' -- Success message
                ELSE 'ERROR A != L + E' -- Error message 
	END AS balance_check, 
    
    -- Percentage Change of major line items from P&L Starts here:
    
/* 
To calculate the percentage change of all major line items for both statements, the formula for such calculation has been applied 
(Percentage Change = ((Old Number - New Number) / Old Number) * 100) in every major line items. 

All percentage change queries for each major line items follow the same structure, with different filters depending on the line item. 
In all of these cases, the subtracted "New Number" is the old number - 1, since we our goal here is to calculate the % change vs the previous year.
*/
    
    -- 1. Percentage Change in Revenue:
    
    CONCAT('%', FORMAT(((((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year  -- The EXTRACT function gets us the year selected through p_year, making it possible for the code to run with year inputed
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'REV')
            -     -- Subtracting old value (REV) from initial value (REV) 
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  -- Extracting the previous year of the one selected, so we can compare this year's data with the previous one
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'REV')) -- filtering by Revenue
            / -- Dividing the (old value - initial value) by initial value
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'REV')) * 100), 2))
	AS percentage_change_revenue,
            
            -- 2. Percentage Change in Other Income:
            
	CONCAT('%', FORMAT(((((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'OI') -- filtering by Other Income
            -  -- Subtracting old value (OI) from initial value (OI) 
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1   
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'OI')) 
            /  -- Dividing the (old value - initial value) by initial value
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'OI')) * 100), 2))
	AS percentage_change_other_income,
			
            -- 3. Percentage Change in COGS:

	CONCAT('%', FORMAT(((((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'COGS') -- filtering by COGS
            -   -- Subtracting old value (COGS) from initial value (COGS) 
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'COGS')) 
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'COGS')) * 100), 2))
	AS percentage_change_COGS,
            
            -- 4. Percentage Change in Selling Expenses: 
            
	CONCAT('%', FORMAT(((((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'SEXP') -- filtering by SEXP
            -    -- Subtracting old value (SEXP) from initial value (SEXP) 
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'SEXP')) 
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = 1 -- has to be exchanged for p_company_id later  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'SEXP')) * 100), 2)) 
	AS percentage_change_selling_expenses,
		
        -- 5. Percentage change in Other Expenses: 
        
	CONCAT('%', FORMAT(((((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'OEXP') -- Filtering by OEXP
            -   -- Subtracting old value (OEXP) from initial value (OXP) 
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'OEXP')) 
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'OEXP')) * 100), 2))
	AS percentage_change_other_expenses,
    
            -- 6. Percentage change in Income Tax:
            
	CONCAT('%', FORMAT(((((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'INCTAX') -- Filtering by Income Tax
            -   -- Subtracting old value (INCTAX) from initial value (INCTAX) 
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'INCTAX')) 
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'INCTAX')) * 100), 2))
	AS percentage_change_income_tax,
    
    -- Calculating Percentage Change of Balance Sheet's major lines. Starts Shere:
    -- 1. Percentage change in Current Assets: 
    
    CONCAT('%', FORMAT(((((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'CA') -- Filtering by current assets 
            -     -- Subtracting old value (CA) from initial value (CA) 
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'CA'))
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'CA')) * 100), 2))
	AS percentage_change_current_assets,
            
			-- 1. Percentage change in Fixed Assets: 
            
	CONCAT('%', FORMAT(((((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'FA') -- Filtering by fixed assets 
            -   -- Subtracting old value (FA) from initial value (FA) 
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'FA'))
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'FA')) * 100), 2))
	AS percentage_change_fixed_assets,
            
			-- 1. Percentage change in Deferred Assets: 
            
	CONCAT('%', FORMAT(((((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'DA') -- Filtering by deferred assets
            -  -- Subtracting old value (DA) from initial value (DA) 
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'DA'))
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'DA')) * 100), 2))
	AS percentage_change_deferred_assets,
            
            -- 2. Percentage change in Liabilities:
            
	CONCAT('%', FORMAT(((((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'CL') -- filterinng by current liabilities
            -   -- Subtracting old value (CL) from initial value (CL) 
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'CL'))
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'CL')) * 100), 2)) 
	AS percentage_change_liabilities,
            
            -- 3. Percentage change in Equity: 
            
	CONCAT('%', FORMAT(((((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'EQ') -- filtering by equity 
            -  -- Subtracting old value (EQ) from initial value (EQ) 
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'EQ'))
            /   -- Dividing the (old value - initial value) by initial value
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year - 1  
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND st.statement_section_code = 'EQ')) * 100), 2)) 
	AS percentage_change_equity,
    
    /*
    2 good metrics to consider are gross margin abosolut as well as percentage values. These allow us to see the amount of money the compnany 
    has left after subtracting all COGS and the percentage this represents. This tells us if the business has a lot of room to reinvest profit 
    into the business and whether or not paying dividends is a good idea at this stage. 
    */
    
    -- Calculating Gross Margin Absolute (additional metric to analyze the startup) Formula: Gross Margin = Net Sales - COGS
    
    CONCAT('$',FORMAT((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND (st.statement_section_code = 'REV'))	-- Total revenue of the year in question 
            -
			(SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND (st.statement_section_code = 'COGS') -- Total costs of the year in question 
		), 2))-- FORMATING the data in the us currency with 2 decimal places
	AS gross_margin_absolute,
        
		-- Calculating Gross Margin as percentage (additional metric to analyze the startup). Formula: (Net Sales - COGS) * 100/Net Sales
        
	CONCAT('%', FORMAT(((SELECT SUM(jeli.debit) -- Summing all debit entries
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND (st.statement_section_code = 'REV'))	-- Total revenue of the year in question 
            
            -            -- Subtracting COGS from Net Sales 
            
			(SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND (st.statement_section_code = 'COGS') -- Total costs of the year in question 
			)) * 100 
            
            /         -- Dividing gross margin x 100 by Net Sales, to get the percentage 
            
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = p_year 
			AND a.company_id = p_company_id  -- Allows us, keep the query working after inputting any available company_id
            AND (st.statement_section_code = 'REV')), 2)) -- Filtering by REV (revenue) to get the Net Sales value, which is what it's been used to divide 
	AS gross_margin_relative
 

FROM account
LIMIT 1;



END$$
DELIMITER ;

CALL H_Accounting.Dessert12_maint1(2020, 1);
