import falcon

from controllers.todo_state import TodoState
from middlewares import RequireJSON

app = falcon.API(middleware=[RequireJSON()])
app.add_route("/api/state/{state_name}", TodoState())
