-- ============================================================
-- The output have been generated with the assistance of Claude at 2026-06-30T20:05:22Z UTC.
-- The content has been verified by the designated engineer.
-- ============================================================

{#
  Macro: generate_schema_name
  Purpose: Use custom_schema_name (e.g. SILVER) directly without target-schema prefix.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}{{ default_schema }}
    {%- else -%}{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
