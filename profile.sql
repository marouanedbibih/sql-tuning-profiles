-- Connexion à SQL*Plus avec les privilèges appropriés.
-- Assurez-vous que l'utilisateur a les droits nécessaires pour exécuter ces commandes.
-- Assurez-vous que vous disposez d'une licence Oracle SQL valide.

-- Étape 1 : Sélectionner les employés ayant un salaire supérieur à 5000.
-- Cette requête extrait les employés remplissant le critère de salaire spécifié.

SELECT employee_id, first_name, last_name, salary 
FROM employees
WHERE salary > 5000;

-- Étape 2 : Implémentation d'un SQL Profile.
-- Le SQL Profile est basé sur une tâche créée par SQL Tuning Advisor pour optimiser une requête spécifique.

DECLARE
  my_sqlprofile_name VARCHAR2(30); -- Variable pour stocker le nom du SQL Profile.
BEGIN
  -- Acceptation d'un SQL Profile pour optimiser une tâche spécifique.
  my_sqlprofile_name := DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(
    task_name    => 'EMP_SALARY_TUNING_TASK', -- Nom de la tâche d'optimisation.
    name         => 'EMP_SALARY_PROFILE',    -- Nom du SQL Profile à créer.
    profile_type => DBMS_SQLTUNE.PX_PROFILE, -- Type du profil (ici, profil parallélisé).
    force_match  => true                     -- Applique le profil même si le texte SQL diffère légèrement.
  );
END;
/

-- Étape 3 : Liste des SQL Profiles existants.
-- Affiche les SQL Profiles définis dans la base de données, avec leurs catégories et statuts.

COLUMN category FORMAT a10
COLUMN sql_text FORMAT a40

SELECT NAME, SQL_TEXT, CATEGORY, STATUS
FROM   DBA_SQL_PROFILES;

-- Explication :
-- 1. `NAME` : Nom du SQL Profile.
-- 2. `SQL_TEXT` : Texte SQL associé au profil.
-- 3. `CATEGORY` : Catégorie où se trouve le profil.
-- 4. `STATUS` : Statut du profil (ACTIF/INACTIF).

-- Étape 4 : Modification d'un SQL Profile.
-- Modifie la catégorie du SQL Profile pour le tester dans un environnement spécifique.

VARIABLE pname VARCHAR2(30);
BEGIN
  -- Définir le nom du profil à modifier.
  :pname := 'EMP_SALARY_PROFILE';
  DBMS_SQLTUNE.ALTER_SQL_PROFILE(
    name            => :pname,         -- Nom du profil.
    attribute_name  => 'CATEGORY',     -- Attribut à modifier (ici, la catégorie).
    value           => 'TEST'          -- Nouvelle valeur de la catégorie.
  );
END;

-- Définir la catégorie SQLTUNE de la session pour effectuer des tests.
ALTER SESSION SET SQLTUNE_CATEGORY = 'TEST';

-- Revenir à la catégorie par défaut.
BEGIN 
  DBMS_SQLTUNE.ALTER_SQL_PROFILE(
    name            => :pname,         -- Nom du profil.
    attribute_name  => 'CATEGORY',     -- Attribut à modifier (ici, la catégorie).
    value           => 'DEFAULT'       -- Réinitialisation à la valeur par défaut.
  );
END;

-- Étape 5 : Suppression d'un SQL Profile.
-- Supprime un SQL Profile existant de la base de données.

BEGIN
  DBMS_SQLTUNE.DROP_SQL_PROFILE(
    name => 'EMP_SALARY_PROFILE' -- Nom du SQL Profile à supprimer.
  );
END;
/

-- Étape 6 : Transport d'un SQL Profile.
-- Crée une table de staging pour transporter les profils vers une autre base.

BEGIN
  DBMS_SQLTUNE.CREATE_STGTAB_SQLPROF(
    table_name  => 'EMPLOYEE_PROFILE_TABLE', -- Nom de la table de staging.
    schema_name => 'HR'                      -- Schéma où la table sera créée.
  );
END;
/

-- Exportation d'un SQL Profile vers la table de staging.
-- Exemple d'exportation du profil 'EMP_SALARY_PROFILE'.

BEGIN
  DBMS_SQLTUNE.PACK_STGTAB_SQLPROF(
    profile_name         => 'EMP_SALARY_PROFILE', -- Nom du SQL Profile à exporter.
    staging_table_name   => 'EMPLOYEE_PROFILE_TABLE', -- Nom de la table de staging.
    staging_schema_owner => 'HR'                      -- Propriétaire du schéma.
  );
END;
/

-- Importation d'un SQL Profile depuis une table de staging.
-- Permet de restaurer le profil dans un autre environnement.

BEGIN
  DBMS_SQLTUNE.UNPACK_STGTAB_SQLPROF(
    replace            => true,                    -- Remplace les profils existants si nécessaire.
    staging_table_name => 'EMPLOYEE_PROFILE_TABLE' -- Table contenant les profils à restaurer.
  );
END;
/
