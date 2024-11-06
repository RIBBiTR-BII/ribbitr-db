librarian::shelf(tidyverse, RIBBiTR-BII/ribbitrrr)

dbcon = hopToDB("ribbitr")

dbExecute(dbcon, "set search_path to survey_data")

cap_sql <- "select l.location, r.region, s2.site, s2.site_id, s2.elevation_m, v.date, c.species_capture, c.life_stage, c.sex, c.svl_mm, c.body_mass_g, q.bd_swab_id, q.detected, q.average_target_quant      
from capture c
left join survey s on c.survey_id = s.survey_id
left join visit v on s.visit_id = v.visit_id
left join site s2 on v.site_id = s2.site_id
left join region r on s2.region_id = r.region_id
left join location l on r.location_id = l.location_id
left join qpcr_bd_results q on c.bd_swab_id = q.bd_swab_id
where r.region in ('california')"   

sndat = dbGetQuery(dbcon, cap_sql)
