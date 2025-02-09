--===================DE KindleA=======================
------ table to store CID list for Targeted group -------
DROP TABLE IF EXISTS Temp.EU_DE_KindleA_T;
CREATE TABLE Temp.EU_DE_KindleA_T
(
    cid numeric(38,0) NULL encode zstd
);

GRANT ALL ON Temp.EU_DE_KindleA_T TO user_name;
commit;

COPY Temp.EU_DE_KindleA_T
FROM 's3://eu-device/KindleA_DE_Test.txt'
iam_role'arn:aws:iam::987654321098:role/RedshiftCopyUnload'
delimiter '\t'
IGNOREHEADER 1;
commit;

------ table to store CID list for Holdout group -------
DROP TABLE IF EXISTS Temp.EU_DE_KindleA_C;
CREATE TABLE Temp.EU_DE_KindleA_C
(
    cid numeric(38,0) NULL encode zstd
);

GRANT ALL ON Temp.EU_DE_KindleA_C TO user_name;
commit;

COPY Temp.EU_DE_KindleA_C
FROM 's3://eu-device/KindleA_DE_Control.txt'
iam_role'arn:aws:iam::987654321098:role/RedshiftCopyUnload'
delimiter '\t'
IGNOREHEADER 1;
commit;

--- TARGETED GROUP: Total number of devices sold ---
with device_ID_DE as
    (
        select distinct 
              component_device_id
            , component_device
            
        from core.device_metadata
        
        where marketplace_id=4
            and family='KINDLE'
            and device_ID in ('D2024001', 'D2024002', 'D2024003')
    )
    
select 
      component_device
    , sum(quantity) as units
    
from devices.Device_order_items a
    inner join Temp.EU_DE_KindleA_T b
        on a.ordering_Customer_id=b.cid
    inner join device_ID_DE c
        on a.device_ID=c.component_device_id
        
where marketplace_id=4
    and to_Date(order_Day,'yyyy/mm/dd') between to_Date('2024/02/01','yyyy/mm/dd') and to_Date('2024/02/10','yyyy/mm/dd')
    and order_item_level_condition<>6 -- did not cancel the order

group by 1;

--- HOLDOUT GROUP: Total number of devices sold ---
with device_ID_DE as
    (
        select distinct 
             component_device_id
            ,component_device
            
        from core.device_metadata
        
        where marketplace_id=4
            and component_family='KINDLE'
            and device_ID in ('D2024001', 'D2024002', 'D2024003')
    )
    
select 
      component_device
    , sum(quantity) as units
    
from devices.Device_order_items a
    inner join Temp.EU_DE_KindleA_C b
        on a.ordering_Customer_id=b.cid
    inner join device_ID_DE c
        on a.device_ID=c.component_device_id
        
where marketplace_id=4
    and to_Date(order_Day,'yyyy/mm/dd') between to_Date('2024/02/01','yyyy/mm/dd') and to_Date('2024/02/10','yyyy/mm/dd')
    and order_item_level_condition<>6

group by 1;

--- TARGETED GROUP: Total number of devices sold for the specific PROMO ---
with device_ID_DE_promo as
    (
        select distinct 
              component_device_id
            , component_device
            
        from core.device_metadata
            where marketplace_id=4
                and component_family='KINDLE'
                and device_ID in ('D2024001', 'D2024002', 'D2024003')
    )

select 
    sum(quantity) as units
from devices.Device_order_items a
    inner join Temp.EU_DE_KindleA_T b
        on a.ordering_Customer_id=b.cid
    inner join device_ID_DE_promo c
        on a.device_ID=c.component_device_id
where marketplace_id=4
    and to_Date(order_Day,'yyyy/mm/dd') between to_Date('2024/02/01','yyyy/mm/dd') and to_Date('2024/02/10','yyyy/mm/dd')
    and order_id in
    (
        select distinct order_id from core.kd_promotion_order_txns
        where promo_id='PROMO2024001'
    );
    
