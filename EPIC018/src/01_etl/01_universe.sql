--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--universo clientes
truncate table tmp_ingcashbcacei_univclie;
insert into tmp_ingcashbcacei_univclie
--create table tmp_ingcashbcacei_univclie tablespace d_aml_99 as
     select distinct a.codclavecic,a.codunicocli,
                     case
                         when c.codsegmento in('ES','EJ','EM') then 'E'
                         when c.codsegmento in('CL','EU') then 'I'
                         else 'C'
                     end as tipbanca,d.desacteconomica
     from ods_v.md_clienteg94 a
          left join  ods_v.mm_descodigosubsegmento b on a.codsubsegmento=b.codsubsegmento
          left join  ods_v.mm_descodsubseggen  c on b.codsubseggeneral=c.codsubseggeneral
		  left join  ods_v.mm_descodactividadeconomica d on a.codacteconomica=d.codacteconomica
     where c.codsegmento in ('ES','CL','EU','EJ','EM','CC','CC','CI') and
           a.tipper<>'P' and
		   a.flgregeliminado='N';

--universo cuentas
truncate table tmp_ingcashbcacei_univctasclie;
insert into tmp_ingcashbcacei_univctasclie
--create table tmp_ingcashbcacei_univctasclie tablespace d_aml_99 as
       select a.*,b.codclaveopecta as codclaveopecta ,b.codopecta as codopecta
       from tmp_ingcashbcacei_univclie a
             left join ods_v.md_cuentag94  b on a.codclavecic=b.codclavecic
       where b.codclaveopecta is not null and
             b.codsistemaorigen in ('SAV','IMP') and
			 b.flgregeliminado='N';

commit;
quit;