{{#PROJECT_ID}}
{{#FTLOGIN}}
# [{{PROJECT_NAME}}](https://projects.intra.42.fr/{{PROJECT_ID}}/{{FTLOGIN}})
{{/FTLOGIN}}
{{^FTLOGIN}}
# [{{PROJECT_NAME}}](https://projects.intra.42.fr/projects/{{PROJECT_ID}})
{{/FTLOGIN}}
{{/PROJECT_ID}}
{{^PROJECT_ID}}
# {{PROJECT_NAME}}
{{/PROJECT_ID}}

## License

This project is licensed under the [ISC License](./LICENSE).
