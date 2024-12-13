with 
A as  -- A查询使用窗口函数 SUM 累积每天及之前的上架商品总数
(select start_date,sum(上架商品数)over(order by start_date) as 截至当日上架商品总数
from 
(select start_date,count(*) as 上架商品数
from products
group by start_date) as a),
B as  -- B查询计算“每个订单日期内三天内销售出的不同产品类目数量”
(SELECT b.order_date, COUNT(DISTINCT b.product_id) as 三天内销出的产品类目
FROM 
(
    SELECT o1.order_date, o2.product_id
    FROM orders AS o1
    LEFT JOIN orders AS o2
    ON DATEDIFF(o1.order_date, o2.order_date) BETWEEN 0 AND 2
) AS b
GROUP BY b.order_date),
C as -- 将 B 和 A 联接，关联订单日期 (order_date) 和商品上架日期 (start_date)，并使用 ROW_NUMBER 分组排序，确保每个订单日期只保留一个最近的上架日期记录。
( select *,row_number() over(partition by order_date order by start_date desc) as rn
from B left join A on B.order_date >= A.start_date)

select order_date,  --  计算“动销率”和“滞销率”
       三天内销出的产品类目,
       截至当日上架商品总数,
       concat(round(三天内销出的产品类目/截至当日上架商品总数,2) *100 ,'%')as 动销率,
	   concat((1- round(三天内销出的产品类目/截至当日上架商品总数,2))*100,'%')as 滞销率
from C where rn=1

