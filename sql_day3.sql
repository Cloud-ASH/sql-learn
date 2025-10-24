USE NORTHWIND
GO

-- 1. List all cities that have both Employees and Customers.
SELECT DISTINCT cCity.City
FROM Customers AS cCity
INNER JOIN (
    SELECT CITY
    FROM Employees
) AS eCity ON cCity.City = eCity.City

SELECT DISTINCT c.City
FROM Customers AS c
INTERSECT
SELECT e.City
FROM Employees AS e

-- 2. List all cities that have Customers but no Employee.
-- SQL Set operations (UNION, INTERSECT, EXCEPT) will automatically remove duplicate, unless use ALL (like UNION ALL) so don't need to use DISTINCT
-- a. Use sub-query
SELECT DISTINCT c.City
FROM Customers c
WHERE c.City NOT IN (
    SELECT e.City
    FROM Employees e
)

-- b. Do not use sub-query
SELECT c.City
FROM Customers AS c
EXCEPT
SELECT e.City
FROM Employees AS e

-- 3. List all products and their total order quantities throughout all orders.
SELECT ProductName, COALESCE(SUM(od.Quantity), 0) AS TotalOrderQuantities
FROM Products p LEFT JOIN [Order Details] od ON p.ProductID = od.ProductID
GROUP BY ProductName
ORDER BY COALESCE(SUM(od.Quantity), 0) DESC

-- 4. List all Customer Cities and total products ordered by that city.
SELECT DISTINCT c.City, SUM(c1.TotalProductsByCustomer) AS TotalProducts
FROM Customers c LEFT JOIN (
    SELECT o.CustomerID, SUM(od.Quantity) AS TotalProductsByCustomer
    FROM [Order Details] od INNER JOIN Orders o ON od.OrderID = o.OrderID
    GROUP BY o.CustomerID
) AS c1 ON c.CustomerID = c1.CustomerID
GROUP BY c.city
ORDER BY TotalProducts DESC

-- better way to do
SELECT c.City, COALESCE(SUM(od.Quantity), 0) AS TotalProducts
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN [Order Details] od ON od.OrderID = o.OrderID
GROUP BY c.city
ORDER BY TotalProducts DESC

-- 5. List all Customer Cities that have at least two customers.
SELECT City, COUNT(DISTINCT CustomerID) AS UniqCustomers
FROM Customers
GROUP BY city
HAVING COUNT(DISTINCT CustomerID) >= 2
ORDER BY COUNT(DISTINCT CustomerID) DESC

-- 6. List all Customer Cities that have ordered at least two different kinds of products.
SELECT c.City, COUNT(DISTINCT od.ProductID) AS KindsOfProducts
FROM Customers c 
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.City
HAVING COUNT(DISTINCT od.ProductID) >= 2
ORDER BY KindsOfProducts DESC

-- 7. List all Customers who have ordered products, but have the ‘ship city’ on the order different from their own customer cities.
SELECT DISTINCT c.CustomerID, c.ContactName
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.City IS NOT NULL AND c.City <> o.ShipCity

-- same
SELECT DISTINCT c.CustomerID, c.ContactName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.City <> o.ShipCity


-- 8. List 5 most popular products, their average price, and the customer city that ordered most quantity of it.

-- Not working
-- SELECT p.ProductName, SUM(Quantity) AS TotalQuantity, SUM(od.UnitPrice * Quantity) / SUM(Quantity) AS AvgPrice, RANK() OVER (ORDER BY SUM(Quantity) DESC) AS RNK
-- FROM Customers c 
-- LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
-- LEFT JOIN [Order Details] od ON o.OrderID = od.OrderID
-- LEFT JOIN ProductS p ON p.ProductID = od.ProductID
-- GROUP BY p.ProductName

-- Three Steps: (USE CTE)
-- 1. Get stats for products (AvgPrice, TotalQuantity)
-- 2. Get top city for every product
-- 3. Rank top product and the corresponding top city
WITH ProductStats AS (
    SELECT TOP 5 p.ProductID, p.ProductName, SUM(od.Quantity) AS TotalQuantity, SUM(od.UnitPrice * od.Quantity) / SUM(od.Quantity) AS AvgPrice
    FROM Products p
    INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName
    ORDER BY TotalQuantity DESC
),
TopCities AS (
    SELECT p.ProductID, c.City, SUM(od.Quantity) AS CityQuantity, ROW_NUMBER() OVER (PARTITION BY p.ProductID ORDER BY SUM(od.Quantity) DESC) AS CityRNK
    FROM Products p
    INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    INNER JOIN Customers c ON o.CustomerID = c.CustomerID
    GROUP BY p.ProductID, c.City
)
SELECT ps.ProductName, ps.TotalQuantity, ps.AvgPrice, tc.City AS TopCity
FROM ProductStats ps INNER JOIN TopCities tc ON ps.ProductID = tc.ProductID
WHERE CityRNK = 1


-- 9. List all cities that have never ordered something but we have employees there.
-- a. Use sub-query
SELECT DISTINCT e.City
FROM Employees e
WHERE e.City NOT IN (
    SELECT DISTINCT ShipCity
    FROM Orders
    WHERE ShipCity IS NOT NULL
)

-- b. Do not use sub-query
SELECT DISTINCT e.City
FROM Employees e
EXCEPT
SELECT DISTINCT o.ShipCity
FROM Orders o


-- 10.  List one city, if exists, that is the city from where the employee sold most orders (not the product quantity) is,
--  and also the city of most total quantity of products ordered from. (tip: join  sub-query)
SELECT e.City
FROM Employees e INNER JOIN Orders o ON e.EmployeeID = o.EmployeeID
-- 1. city from where employee sold most orders
WHERE e.City IN (
    SELECT TOP 1 e2.City
    FROM Orders o2
    INNER JOIN Employees e2 ON e2.EmployeeID = o2.EmployeeID
    GROUP BY e2.City
    ORDER BY COUNT(o2.OrderID) DESC
) 
-- 2. city of most total quantity of products ordered from
AND e.City IN (
    SELECT TOP 1 o3.ShipCity
    FROM Orders o3
    INNER JOIN [Order Details] od ON od.OrderID = o3.OrderID
    GROUP BY o3.ShipCity
    ORDER BY SUM(od.Quantity)
)

-- 11. How do you remove the duplicates record of a table?
-- 1. Use SELECT DISTINCT INTO new_table to create a new table
-- 2. Use GROUP BY to automatically remove duplicate and create a new table
-- 3. Use temptable to hold the non-duplicate table, clear the original table and put the temp table data back into original table.