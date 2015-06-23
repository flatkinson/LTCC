drop table TT_LTCC_CURVE_DATA;

create table TT_LTCC_CURVE_DATA as
select
    a.chembl_id as target_chemblid
  , a.pref_name
  , a.target_type
  , a.organism
  , case
      when (organism = 'Oryctolagus cuniculus' or assay_organism = 'Oryctolagus cuniculus' or regexp_like(description, '(^|\W)(' || 'rabbit'          || ')(\W|$)', 'i')) then 'Rabbit'
      when (organism = 'Cavia porcellus'       or assay_organism = 'Cavia porcellus'       or regexp_like(description, '(^|\W)(' || 'guinea pig'      || ')(\W|$)', 'i')) then 'Guinea Pig'
      when (organism = 'Sus scrofa'            or assay_organism = 'Sus scrofa'            or regexp_like(description, '(^|\W)(' || 'pig|porcine'     || ')(\W|$)', 'i')) then 'Pig'
      when (organism = 'Felis catus'           or assay_organism = 'Felis catus'           or regexp_like(description, '(^|\W)(' || 'cat|kitten'      || ')(\W|$)', 'i')) then 'Cat'
      when (organism = 'Bos taurus '           or assay_organism = 'Bos taurus'            or regexp_like(description, '(^|\W)(' || 'cow|bovine|calf' || ')(\W|$)', 'i')) then 'Cow'
      when (organism = 'Rattus norvegicus'     or assay_organism = 'Rattus norvegicus')                                                                                   then 'Rat'
      when (organism = 'Homo sapiens'          or assay_organism = 'Homo sapiens')                                                                                        then 'Human'
      else 'Other'
    end as species
  , b.relationship_type
  , b.chembl_id as assay_chemblid
  , b.description
  , b.assay_organism
  , h.chembl_id as parent_cmpd_chemblid
  , g.chembl_id as cmpd_chemblid
  , c.standard_type
  , c.standard_relation
  , c.standard_value
  , c.standard_units
  , c.pchembl_value
  , c.activity_comment
  , c.data_validity_comment
  , c.potential_duplicate
  , d.compound_key
  , c.published_type
  , c.published_relation
  , c.published_value
  , c.published_units
  , e.chembl_id as doc_chemblid
  , e.pubmed_id
  , e.journal || ', v. ' || e.volume || ', p. ' || e.first_page || ' (' || e.year || ')' as reference
  , case when pchembl_value >= 5.0 then 1 end as active
from
       chembl_20_app.target_dictionary a
  join chembl_20_app.assays b             on a.tid             = b.tid
  join chembl_20_app.activities c         on b.assay_id        = c.assay_id
  join chembl_20_app.compound_records d   on c.record_id       = d.record_id
  join chembl_20_app.docs e               on c.doc_id          = e.doc_id
  join chembl_20_app.molecule_hierarchy f on c.molregno        = f.molregno
  join chembl_20_app.chembl_id_lookup g   on f.molregno        = g.entity_id
  join chembl_20_app.chembl_id_lookup h   on f.parent_molregno = h.entity_id
where
    g.entity_type = 'COMPOUND' and h.entity_type = 'COMPOUND'
and c.standard_type in ('IC50', 'EC50', 'ED50', 'AC50', 'XC50', 'Ki', 'Kd', 'Potency') -- Dose-response assays
and (
      (c.standard_units = 'nM' and c.standard_value is not null) -- N.B. Any relation accepted
   or regexp_like(c.activity_comment, '(^|\W)' || '(not active|inactive|no activity|no inhibition|no effect)' || '(\W|$)', 'i') -- Inactives without numerical value
)
and lower(a.pref_name) like 'voltage-gated l-type calcium channel%'
order by
    a.chembl_id
  , b.chembl_id
  , h.chembl_id
;