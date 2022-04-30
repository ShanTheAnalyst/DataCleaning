/*
Cleaning Data in SQL Queries
*/


Select *
From DataCleaning.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

Select SaleDate, Convert(Date, SaleDate)
From DataCleaning.dbo.NashvilleHousing

-- If Update comand not work try Alter
Update DataCleaning.dbo.NashvilleHousing
SET SaleDate = Convert(Date, SaleDate)

Alter Table DataCleaning.dbo.NashvilleHousing
Add SaleDateConverted date;

Update DataCleaning.dbo.NashvilleHousing
SET SaleDateConverted = Convert(Date, SaleDate)

Select SaleDateConverted
From DataCleaning.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From DataCleaning.dbo.NashvilleHousing
Where PropertyAddress is NULL
Order By ParcelID

-- Populating NULL Adresses
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From DataCleaning.dbo.NashvilleHousing a
JOIN DataCleaning.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is NULL


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From DataCleaning.dbo.NashvilleHousing a
JOIN DataCleaning.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is NULL

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress, 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
From DataCleaning.dbo.NashvilleHousing


Alter Table DataCleaning..NashvilleHousing
Add PropertySplitAddress nvarchar(255);

Update DataCleaning..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)


Alter Table DataCleaning..NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update DataCleaning..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


------- Doing same thing like above but using PARSENAME method ---------------


-- ParseName perform the funtionality backward
Select 
PARSENAME(Replace(OwnerAddress, ',', '.'), 3),
PARSENAME(Replace(OwnerAddress, ',', '.'), 2),
PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
From DataCleaning..NashvilleHousing


Alter Table DataCleaning..NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

Update DataCleaning..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)


Alter Table DataCleaning..NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update DataCleaning..NashvilleHousing
SET OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)

Alter Table DataCleaning..NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update DataCleaning..NashvilleHousing
SET OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

Select *
From DataCleaning..NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From DataCleaning..NashvilleHousing
Group by SoldAsVacant
Order by 2

Select SoldAsVacant,
	Case When SoldAsVacant = 'Y' then 'Yes'
		When SoldAsVacant = 'N' then 'No'	
		Else SoldAsVacant
	End
From DataCleaning..NashvilleHousing

Update DataCleaning..NashvilleHousing
SET SoldAsVacant = Case When SoldAsVacant = 'Y' then 'Yes'
		When SoldAsVacant = 'N' then 'No'	
		Else SoldAsVacant
	End
From DataCleaning..NashvilleHousing


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

With RowNumCTE As(
	Select *, 
	ROW_NUMBER() Over ( Partition By ParcelID, PropertyAddress,SaleDate, 
								SalePrice, LegalReference Order By  ParcelID ) row_num
	From DataCleaning..NashvilleHousing
)

Select *
From RowNumCTE
Where row_num > 1


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From DataCleaning..NashvilleHousing



Alter Table DataCleaning..NashvilleHousing
Drop Column PropertyAddress, OwnerAddress,TaxDistrict, SaleDate 



-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


USE DataCleaning 
GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

GO 


---- Using BULK INSERT

USE DataCleaning;
GO
BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning.csv'
   WITH (
      FIELDTERMINATOR = ',',
      ROWTERMINATOR = '\n'
);
GO


-- Using OPENROWSET
--USE DataCleaning;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO
