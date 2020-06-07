import falcon

from controllers.todo_state import TodoState
from middlewares import RequireJSON, CORSComponent

app = falcon.API(middleware=[RequireJSON(), CORSComponent()])
app.add_route("/api/state/{state_name}", TodoState())
