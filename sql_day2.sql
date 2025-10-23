USE AdventureWorks2019
GO

-- 1. How many products can you find in the Production.Product table?
SELECT COUNT(ProductID) AS TotalNumberOfProducts
FROM Production.Product

-- 2. Write a query that retrieves the number of products in the Production.Product table that are included in a subcategory.
--  The rows that have NULL in column ProductSubcategoryID are considered to not be a part of any subcategory.
SELECT COUNT(ProductID) AS ProductInSubcategory
FROM Production.Product
WHERE ProductSubcategoryID IS NOT NULL

-- 3. How many Products reside in each SubCategory? Write a query to display the results with the following titles.
-- ProductSubcategoryID CountedProducts
-- -------------------- ---------------
SELECT ProductSubcategoryID, COUNT(ProductID) AS CountedProducts
FROM Production.Product
WHERE ProductSubcategoryID IS NOT NULL
GROUP BY ProductSubcategoryID

-- 4. How many products that do not have a product subcategory.
SELECT COUNT(ProductID) AS ProductInSubcategory
FROM Production.Product
WHERE ProductSubcategoryID IS NULL

-- 5. Write a query to list the sum of products quantity in the Production.ProductInventory table.
SELECT SUM(Quantity)
FROM Production.ProductInventory

-- 6. Write a query to list the sum of products in the Production.ProductInventory table and LocationID set to 40 and
--  limit the result to include just summarized quantities less than 100.
--  ProductID    TheSum
--  -----------    ----------

SELECT ProductID, SUM(Quantity) AS TheSum
FROM Production.ProductInventory
WHERE LocationID = 40
GROUP BY ProductID
HAVING SUM(Quantity) < 100

-- use subquery instead of 
SELECT ProductID, t.TheSum
FROM (
    SELECT ProductID, SUM(Quantity) AS TheSum
    FROM Production.ProductInventory
    WHERE LocationID = 40
    GROUP BY ProductID
) AS t
WHERE t.TheSum < 100

-- 7. Write a query to list the sum of products with the shelf information in the Production.ProductInventory table and LocationID set to 40 and limit the result to include just summarized quantities less than 100
--       Shelf      ProductID      TheSum
--    ----------   -----------   -----------
SELECT Shelf, ProductID, SUM(Quantity) AS TheSum
FROM Production.ProductInventory
WHERE LocationID = 40
GROUP BY Shelf, ProductID
HAVING SUM(Quantity) < 100

-- 8. Write the query to list the average quantity for products where column LocationID has the value of 10 from the table Production.ProductInventory table.
SELECT AVG(Quantity) AS AvgQuantity
FROM Production.ProductInventory
WHERE LocationID = 10

-- 9. Write query  to see the average quantity  of  products by shelf  from the table Production.ProductInventory
--    ProductID     Shelf      TheAvg
--    ----------- ---------- -----------
SELECT ProductID, Shelf, AVG(Quantity) AS AvgQuantity
FROM Production.ProductInventory
GROUP BY Shelf, ProductID

-- 10. Write query  to see the average quantity  of  products by shelf excluding rows that has the value of N/A in the column Shelf from the table Production.ProductInventory
--     ProductID     Shelf      TheAvg
--     ----------- ---------- -----------
SELECT ProductID, Shelf, AVG(Quantity) AS AvgQuantity
FROM Production.ProductInventory
WHERE Shelf NOT IN ('N/A') 
-- or Shelf <> 'N/A'
GROUP BY Shelf, ProductID

-- 11. List the members (rows) and average list price in the Production.Product table. This should be grouped independently over the Color and the Class column. Exclude the rows where Color or Class are null.
--     Color            Class     TheCount          AvgPrice
--     -------------- - -----    -----------    ---------------------
SELECT Color, Class, COUNT(ProductID) AS TheCount, AVG(ListPrice) AS AvgPrice
FROM Production.Product
WHERE Color IS NOT NULL AND Class IS NOT NULL
GROUP BY Color, Class


-- Joins:

-- 12. Write a query that lists the country and province names from person. CountryRegion and person. StateProvince tables. Join them and produce a result set similar to the following.
--     Country                        Province
--     ---------                          ----------------------
SELECT c.Name AS Country, s.Name AS Province
FROM person.CountryRegion c FULL OUTER JOIN person.StateProvince s ON c.CountryRegionCode = s.CountryRegionCode

-- 13. Write a query that lists the country and province names from person. CountryRegion and person. StateProvince tables and list the countries filter them by Germany and Canada.
--     Join them and produce a result set similar to the following.
--     Country                        Province
--     ---------                          ----------------------
--     ---------                          ----------------------
-- no need to use derived table here since we don't have GROUP BY to avoid
SELECT ct.Country, s.Name AS Province
FROM (
    SELECT c.CountryRegionCode, c.Name AS Country
    FROM person.CountryRegion c
    WHERE c.Name IN ('Germany', 'Canada')
) AS ct LEFT JOIN person.StateProvince s ON ct.CountryRegionCode = s.CountryRegionCode

SELECT c.Name AS Country, s.Name as Province
FROM person.CountryRegion c LEFT JOIN person.StateProvince s ON c.CountryRegionCode = s.CountryRegionCode
WHERE c.Name IN ('Germany', 'Canada')


--  Using Northwnd Database: (Use aliases for all the Joins)
USE Northwind
GO

-- 14.  List all Products that has been sold at least once in last 27 years.
-- Find qualify records first, then link with productID
SELECT DISTINCT od.ProductID
FROM [Order Details] od INNER JOIN (
    SELECT o.OrderID
    FROM Orders o 
    WHERE DATEDIFF(YEAR, o.OrderDate, GETDATE()) < 27
) AS s ON od.OrderID = s.OrderID

-- another way to do without subquery
-- Linke with ProductId first, then find qualify records
SELECT DISTINCT od.ProductID
FROM [Order Details] od INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE DATEDIFF(YEAR, o.OrderDate, GETDATE()) < 27

-- 15.  List top 5 locations (Zip Code) where the products sold most.
-- most by quantity
SELECT TOP 5 o.ShipPostalCode, SUM(od.Quantity) AS ProdutsSold
FROM [Order Details] od INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.ShipPostalCode IS NOT NULL
GROUP BY o.ShipPostalCode
ORDER BY ProdutsSold DESC

-- most by revenue
SELECT TOP 5 o.ShipPostalCode, SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS ProdutsSold
FROM [Order Details] od INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.ShipPostalCode IS NOT NULL
GROUP BY o.ShipPostalCode
ORDER BY ProdutsSold DESC

-- 16.  List top 5 locations (Zip Code) where the products sold most in last 27 years.
SELECT TOP 5 o.ShipPostalCode, SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS ProdutsSold
FROM [Order Details] od INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.ShipPostalCode IS NOT NULL AND DATEDIFF(YEAR, o.OrderDate, GETDATE()) < 27
GROUP BY o.ShipPostalCode
ORDER BY ProdutsSold DESC

-- 17.   List all city names and number of customers in that city.   
SELECT City, COUNT(CustomerID) AS CustomerNum
FROM Customers
GROUP BY City
ORDER BY CustomerNum DESC

-- 18.  List city names which have more than 2 customers, and number of customers in that city
SELECT City, COUNT(CustomerID) AS CustomerNum
FROM Customers
GROUP BY City
HAVING COUNT(CustomerID) > 2
ORDER BY CustomerNum DESC

-- 19.  List the names of customers who placed orders after 1/1/98 with order date.
SELECT DISTINCT c.ContactName, o.OrderDate
FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate > '1998-01-01'
ORDER BY o.OrderDate

-- 20.  List the names of all customers with most recent order dates
SELECT c.ContactName, MAX(o.OrderDate)
FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.ContactName

-- I misunderstand the quesition to get those customers who purchase at the same day of most recent order, and here's the corresponding queries
-- SELECT DISTINCT c.CompanyName, c.ContactName, o.OrderDate
-- FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID
-- WHERE o.OrderDate = (
--     SELECT MAX(OrderDate)
--     FROM Orders
-- )
-- ORDER BY c.CompanyName


-- 21.  Display the names of all customers  along with the  count of products they bought
SELECT c.contactName, SUM(Quantity) AS ProductsBought
FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.ContactName
ORDER BY ProductsBought DESC


-- 22.  Display the customer ids who bought more than 100 Products with count of products.
SELECT c.contactName, SUM(Quantity) AS ProductsBought
FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.ContactName
HAVING SUM(Quantity) > 100
ORDER BY ProductsBought DESC


-- 23.  List all of the possible ways that suppliers can ship their products. Display the results as below
--     Supplier Company Name                Shipping Company Name
--    -------------------------------            ----------------------------------

-- should use cross join here
SELECT sup.CompanyName AS 'Supplier Company Name', ship.CompanyName AS 'Shipping Company Name'
FROM Shippers ship CROSS JOIN Suppliers sup

-- 24.  Display the products order each day. Show Order date and Product Name.
SELECT o.OrderDate, p.ProductName, SUM(Quantity) AS OrderEachDay
FROM Orders o INNER JOIN [Order Details] od ON o.OrderID = od.OrderID INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY o.OrderDate, p.ProductName
ORDER BY o.OrderDate DESC, OrderEachDay DESC

-- 25.  Displays pairs of employees who have the same job title.

-- should use self join
SELECT e1.Title, e1.FirstName + ' ' + e1.LastName AS 'Name 1', e2.FirstName + ' ' + e2.LastName AS 'Name 2'
FROM Employees e1 LEFT JOIN Employees e2 ON e1.Title = e2.Title
-- use < instead of <> to avoid one records(pair) are displayed twice
WHERE e1.EmployeeID < e2.EmployeeID
ORDER BY e1.Title, 'Name 1', 'Name 2'

-- 26.  Display all the Managers who have more than 2 employees reporting to them.

-- -- need to loop all the employees so that we can find how many reportsFrom we have for each manager
-- SELECT *
-- FROM Employees

-- SELECT e1.FirstName + ' ' + e1.LastName AS 'Full Name'
-- FROM Employees e1
-- WHERE e1.Title = 'Sales Manager'

-- No need to use recursive cte since we dont' need to separate "layers"
SELECT e1.FirstName + ' ' + e1.LastName AS 'Full Name', COUNT(e2.EmployeeID) AS NumReportsTo
FROM Employees e1 INNER JOIN Employees e2 ON e1.EmployeeID = e2.ReportsTo
GROUP BY e1.FirstName, e1.LastName
HAVING COUNT(e2.EmployeeID) > 2
ORDER BY NumReportsTo DESC

-- 27.  Display the customers and suppliers by city. The results should have the following columns
-- City
-- Name
-- Contact Name,
-- Type (Customer or Supplier)

-- should use union, but seems type & column number not same, need to pre-process
-- when use UNION, it's not compulsory that both table are identical in terms of column number and type, 
-- just SELECT columns with same number and type from both table and then UNION

-- 'Customer' AS TYPE creates a new column and set value as 'Customer'
SELECT City, CompanyName AS Name, ContactName AS 'ContactName', 'Customer' AS TYPE
FROM Customers

-- UNION ALL will not remove duplicate and is faster (better in this case)
UNION ALL

SELECT City, CompanyName AS Name, ContactName AS 'ContactName', 'Supplier' AS TYPE
FROM Suppliers

ORDER BY City, Name