# node7-strength Recipe Notes

Add this resource to your NODE7 txAdmin recipe as an optional or default framework resource.

## Resource Path

```txt
resources/[node7]/node7-strength
```

## Start Order

```cfg
ensure oxmysql
ensure node7-core
ensure node7-strength
```

## SQL

Use:

```txt
sql/node7_strength.sql
```

## Permissions

Use:

```txt
recipe/permissions.cfg
```
