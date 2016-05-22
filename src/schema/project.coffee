exports.schema =
  name: "project"
  fields:
    title: ""
    description: "text"
    contact: "text"
    start_date: "bigInteger"
    end_date: "bigInteger"
    repos: ""
    creator: "integer"
    timestamp: "bigInteger"
    status: ""
    options: "text"
    flag: 'integer'
    visibility_level: {type: 'integer', default: 0}