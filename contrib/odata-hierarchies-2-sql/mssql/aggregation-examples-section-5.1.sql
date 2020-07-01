USE [SalesDemoDB];

-- Example #1:
-- GET ~/SalesOrganizations?$apply=
--     groupby((rollup(SalesOrgHierarchy)),
--             aggregate($count as OrgCnt)/compute(OrgCnt sub 1 as SubOrgCnt))      
--   &$select=ID,Name,SubOrgCnt
--   &$expand=Superordinate($select=ID)

WITH 
	ancestor_relation ([node],ancestor) AS
	(
		-- all node pairs on a common path
		SELECT id, id
		FROM SalesOrganization
	UNION ALL
		SELECT SalesOrganization.id, ancestor_relation.ancestor
		FROM ancestor_relation INNER JOIN SalesOrganization ON SalesOrganization.Superordinate = ancestor_relation.node
    ) ,
	trafo_1_result ([node],cnt) AS
	(          -- groupby((rollup(...),aggregate(...)
		SELECT ancestor_relation.ancestor, count(*)
		FROM ancestor_relation 
		INNER JOIN SalesOrganization ON ancestor_relation.ancestor = SalesOrganization.id
		GROUP BY ancestor_relation.ancestor
    )
SELECT [node], so1.name, so2.ID, cnt - 1
	-- final result with compute(...), $select and $expand
FROM trafo_1_result
INNER JOIN SalesOrganization so1 ON trafo_1_result.[node] = so1.ID
LEFT JOIN SalesOrganization so2 ON so1.Superordinate = so2.ID
ORDER BY [node]
;

-- example #2:
-- GET ~/SalesOrganizations?$apply=
--     /groupby((rollup(SalesOrgHierarchy)),
--              aggregate(Sales/Amount with sum as TotalAmount))
--     /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)

-- Develop the different transformations in two steps

-- step #1: /groupby((rollup(...)), aggregate(...))
WITH 
	ancestor_relation ([node], ancestor, Amount) AS
	(
		-- all node pairs plus fields to be aggregated (Amount in this example)
		SELECT SalesOrganization.id, SalesOrganization.id, Sales.Amount
		FROM SalesOrganization
		LEFT OUTER JOIN Sales ON SalesOrganization.id = Sales.SalesOrganization
	UNION ALL
		SELECT SalesOrganization.id, ancestor_relation.ancestor, Sales.Amount
		FROM ancestor_relation
		INNER JOIN SalesOrganization ON SalesOrganization.Superordinate = ancestor_relation.[node]
		-- LEFT OUTER JOIN Sales ON SalesOrganization.id = Sales.SalesOrganization
		OUTER APPLY (SELECT Amount FROM Sales WHERE SalesOrganization.id = Sales.SalesOrganization) AS Sales
    )
SELECT ancestor_relation.ancestor, SalesOrganization.Superordinate, sum(ancestor_relation.Amount)
FROM ancestor_relation
INNER JOIN SalesOrganization ON ancestor_relation.ancestor = SalesOrganization.id
GROUP BY ancestor_relation.ancestor, SalesOrganization.Superordinate
;

-- step #2: /groupby((rollup(...)), aggregate(...))/ancestors(...)
WITH 
-- CTEs for groupby(..., aggregate(...))
	ancestor_relation([node],ancestor,Amount) AS
	(
		-- all node pairs plus fields to be aggregated (Amount in this example)
		SELECT SalesOrganization.id, SalesOrganization.id, Sales.Amount
		FROM SalesOrganization
		LEFT OUTER JOIN Sales ON SalesOrganization.id = Sales.SalesOrganization
	UNION ALL
		SELECT SalesOrganization.id, ancestor_relation.ancestor, Sales.Amount
		FROM ancestor_relation
		INNER JOIN SalesOrganization ON SalesOrganization.Superordinate = ancestor_relation.[node]
		-- LEFT OUTER JOIN Sales ON SalesOrganization.id = Sales.SalesOrganization
		OUTER APPLY (SELECT Amount FROM Sales WHERE SalesOrganization.id = Sales.SalesOrganization) AS Sales
    ),
	trafo_1_result(ID, Superordinate, [Name], aggAmount) AS
	(
		SELECT ancestor_relation.ancestor, SalesOrganization.Superordinate, SalesOrganization.[Name], sum(ancestor_relation.Amount)
		FROM ancestor_relation
		INNER JOIN SalesOrganization ON ancestor_relation.ancestor = SalesOrganization.id
		GROUP BY ancestor_relation.ancestor, SalesOrganization.Superordinate, SalesOrganization.[Name]
    ),
	-- CTEs for ancestors(...)
	parent_of([node],parent_node) AS
	(
		SELECT ID, Superordinate
		FROM trafo_1_result
	), -- generic parent relation from hier def
	ancestors_of([node]) AS
	(
		-- set of (parent) start nodes from filter expression passed to ancestors()
	    SELECT ID 
		FROM trafo_1_result
		WHERE charindex('East', [Name])<> 0		
	UNION ALL
		-- generic ancestors recursion derived from hier def
		SELECT parent_node		
		FROM ancestors_of INNER JOIN parent_of ON parent_of.[node] = ancestors_of.[node]
    )
SELECT *
FROM trafo_1_result INNER JOIN ancestors_of ON id = [node]  -- output result
;
