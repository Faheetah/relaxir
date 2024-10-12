defmodule Relaxir.Repo.Migrations.SquashMigrations do
  use Ecto.Migration

  def up do
    execute "DELETE FROM schema_migrations WHERE version = 20200810170900 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200810170900);"
    execute "DELETE FROM schema_migrations WHERE version = 20200812031722 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200812031722);"
    execute "DELETE FROM schema_migrations WHERE version = 20200815130903 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200815130903);"
    execute "DELETE FROM schema_migrations WHERE version = 20200820181401 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200820181401);"
    execute "DELETE FROM schema_migrations WHERE version = 20200821052245 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200821052245);"
    execute "DELETE FROM schema_migrations WHERE version = 20200826044053 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200826044053);"
    execute "DELETE FROM schema_migrations WHERE version = 20200830151806 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200830151806);"
    execute "DELETE FROM schema_migrations WHERE version = 20200920233718 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200920233718);"
    execute "DELETE FROM schema_migrations WHERE version = 20200922024927 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200922024927);"
    execute "DELETE FROM schema_migrations WHERE version = 20200924212033 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200924212033);"
    execute "DELETE FROM schema_migrations WHERE version = 20200929072937 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200929072937);"
    execute "DELETE FROM schema_migrations WHERE version = 20201019012008 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201019012008);"
    execute "DELETE FROM schema_migrations WHERE version = 20201019215618 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201019215618);"
    execute "DELETE FROM schema_migrations WHERE version = 20210202142549 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20210202142549);"
    execute "DELETE FROM schema_migrations WHERE version = 20211123175032 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20211123175032);"
    execute "DELETE FROM schema_migrations WHERE version = 20220212181806 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20220212181806);"
    execute "DELETE FROM schema_migrations WHERE version = 20231001025617 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231001025617);"
    execute "DELETE FROM schema_migrations WHERE version = 20231003034534 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231003034534);"
    execute "DELETE FROM schema_migrations WHERE version = 20231007152901 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231007152901);"
    execute "DELETE FROM schema_migrations WHERE version = 20231007193120 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231007193120);"
    execute "DELETE FROM schema_migrations WHERE version = 20231210153952 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231210153952);"
    execute "DELETE FROM schema_migrations WHERE version = 20241011183650 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20241011183650);"
    execute "DELETE FROM schema_migrations WHERE version = 20230919140356 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20230919140356);"
    execute "DELETE FROM schema_migrations WHERE version = 20200803034934 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200803034934);"
  end
end
