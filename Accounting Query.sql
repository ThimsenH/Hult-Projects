USE H_Accounting;
 
-- Getting the sum of revenue and expenses for a specific year
SELECT 
    st.statement_section_code,
	SUM(jeli.debit),
    SUM(jeli.credit)
FROM account AS a
JOIN statement_section AS st
ON a.balance_sheet_section_id = st.statement_section_id
JOIN journal_entry_line_item AS jeli
ON a.account_id = jeli.account_id
JOIN journal_entry AS je
ON jeli.journal_entry_id = je.journal_entry_id
WHERE EXTRACT(YEAR FROM je.entry_date) = 2016
AND st.is_balance_sheet_section = 1
AND cancelled = 0
GROUP BY st.statement_section_code;

SELECT sum(jeli.debit),  SUM(jeli.credit)
FROM account AS a
JOIN statement_section AS st
ON a.profit_loss_section_id = st.statement_section_id
JOIN journal_entry_line_item AS jeli
ON a.account_id = jeli.account_id
JOIN journal_entry AS je
ON jeli.journal_entry_id = je.journal_entry_id
WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
AND a.company_id = 1 -- has to be exchanged for p_company_id later
AND st.statement_section_code = 'REV';
-- Receive as an argument the year for which the user wants to produce the P&L and B/S statements
	-- CREATE PROCEDURE H_Accounting.Dessert12_main(IN p_year INT(4), IN p_company_id INT) -- we have to name this later!!

-- Do the necessary calculations to obtain the net profit or loss for that year
 SELECT
		CONCAT('$',FORMAT((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'REV' OR st.statement_section_code = 'OI'))	-- Total revenue of 2018
            -
			(SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'COGS' OR st.statement_section_code = 'SEXP' OR st.statement_section_code = 'OEXP' OR st.statement_section_code = 'INCTAX') -- Total costs 2018
		), 2))-- FORMATING the data in the us currency with 2 decimal places
        AS profit_loss_statement
FROM account 
LIMIT 1;


-- Use that value, to produce the B/S
 SELECT
		CONCAT('$',FORMAT((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'CA' OR st.statement_section_code = 'FA' OR st.statement_section_code = 'DA'))	-- Total assets of 2018
           , 2)) -- FORMATING the data in the us currency with 2 decimal places
           AS balance_sheet
FROM account 
LIMIT 1;

-- Demonstrate that A = L + E
 SELECT
		CASE WHEN((SELECT ROUND(SUM(jeli.debit) - SUM(jeli.credit), 2)
					FROM account AS a
					JOIN statement_section AS st
					ON a.balance_sheet_section_id = st.statement_section_id
					JOIN journal_entry_line_item AS jeli
					ON a.account_id = jeli.account_id
					JOIN journal_entry AS je
					ON jeli.journal_entry_id = je.journal_entry_id
					WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
					AND a.company_id = 1 -- has to be exchanged for p_company_id later
                    AND (st.statement_section_code = 'CA' OR st.statement_section_code = 'FA' OR st.statement_section_code = 'DA')
                    AND st.is_balance_sheet_section = 1
					AND cancelled = 0)	-- Total assets of the year
				   ) = 
                   (SELECT ROUND(SUM(jeli.credit) - SUM(jeli.debit), 2)
					FROM account AS a
					JOIN statement_section AS st
					ON a.balance_sheet_section_id = st.statement_section_id
					JOIN journal_entry_line_item AS jeli
					ON a.account_id = jeli.account_id
					JOIN journal_entry AS je
					ON jeli.journal_entry_id = je.journal_entry_id
					WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
                    AND a.company_id = 1 -- has to be exchanged for p_company_id later
					AND (st.statement_section_code = 'CL' OR st.statement_section_code = 'EQ')
                    AND st.is_balance_sheet_section = 1
					AND cancelled = 0) -- Total L + E of the year
				THEN 'A = L + E'
                ELSE 'ERROR A != L + E'
                END AS balance_check
FROM account 
LIMIT 1;

-- Print both the P&L and B/S as clear as possible on the Result Grids
	-- this basically is answered by the previous queries we just have to include them

-- Show the % change vs. the previous year for every major line item on the P&L and B/S
	-- change in P&L
 SELECT (((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'REV')
            -
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'REV')) 
            /
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'REV')) * 100 AS percentage_change_revenue,
            
            (((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'OI')
            -
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'OI')) 
            /
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'OI')) * 100 AS percentage_change_other_income,
            
            (((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'COGS')
            -
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'COGS')) 
            /
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'COGS')) * 100 AS percentage_change_COGS,
            
            (((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'SEXP')
            -
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'SEXP')) 
            /
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'SEXP')) * 100 AS percentage_change_selling_expenses,
		
			(((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'OEXP')
            -
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'OEXP')) 
            /
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'OEXP')) * 100 AS percentage_change_other_expenses,
            
            (((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'INCTAX')
            -
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'INCTAX')) 
            /
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'INCTAX')) * 100 AS percentage_change_income_tax
FROM account
LIMIT 1;
	-- change in balance sheet
SELECT 
			(((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'CA')
            -
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'CA'))
            /
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'CA')) * 100 AS percentage_change_current_assets,
            
            (((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'FA')
            -
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'FA'))
            /
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'FA')) * 100 AS percentage_change_fixed_assets,
            
            (((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'DA')
            -
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'DA'))
            /
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'DA')) * 100 AS percentage_change_deferred_assets,
            
            (((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'CL')
            -
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'CL'))
            /
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'CL')) * 100 AS percentage_change_liabilities,
            
            (((SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'EQ')
            -
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'EQ'))
            /
            (SELECT (SUM(jeli.debit) - SUM(jeli.credit))
			FROM account AS a
			JOIN statement_section AS st
			ON a.balance_sheet_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2017 - 1  -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND st.statement_section_code = 'EQ')) * 100 AS percentage_change_equity
FROM account
LIMIT 1;

-- Give some headings to each major account line item. And to each section of the P&L and B/S
	-- check

-- Add any additional financial metrics and ratios that could be useful to analyze this start-up 
	-- GROSS Margin
SELECT
		CONCAT('$',FORMAT((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'REV'))	-- Total revenue of 2018
            -
			(SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'COGS') -- Total costs 2018
		), 2))-- FORMATING the data in the us currency with 2 decimal places
        AS gross_margin_absolute,
        
        ((SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'REV'))	-- Total revenue of 2018
            -
			(SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'COGS') -- Total costs 2018
			)) * 100
            /
            (SELECT SUM(jeli.debit)
			FROM account AS a
			JOIN statement_section AS st
			ON a.profit_loss_section_id = st.statement_section_id
			JOIN journal_entry_line_item AS jeli
			ON a.account_id = jeli.account_id
			JOIN journal_entry AS je
			ON jeli.journal_entry_id = je.journal_entry_id
			WHERE EXTRACT(YEAR FROM je.entry_date) = 2018 -- has to be exchanged for p_year later
			AND a.company_id = 1 -- has to be exchanged for p_company_id later
            AND (st.statement_section_code = 'REV')) AS gross_margin_relative
FROM account 
LIMIT 1;

-- Wanna ensure an "A"? Produce a cash flow statement  as an added challenge
-- The stored procedure must have comprehensive comments explaining the purpose of each block of code

/*
-- stored procedure
DELIMITER $$

-- Receive as an argument the year for which the user wants to produce the P&L and B/S statements
CREATE PROCEDURE H_Accounting.Dessert12_main(IN p_year YEAR) -- we have to name this later!!
BEGIN


SELECT     
    
END$$
DELIMITER ;


-- CALLing the stored procedure
CALL H_Accounting.test();

*/

