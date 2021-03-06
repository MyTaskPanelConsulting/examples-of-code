from flask import Flask

from flask_admin import Admin
from flask_cors import CORS
import flask_login
from flask_mail import Mail
from flask_restful import Api
from flask_sqlalchemy import SQLAlchemy
from flask_wtf.csrf import CSRFProtect


# App flask
app = Flask(__name__)
# Config flask
app.config.from_object('conf.config')
# CSRF protect
csrf = CSRFProtect(app)

# Config SQLAlchemy and migrations
db = SQLAlchemy(app)
db.init_app(app)
db.app = app

# Cors config
CORS(
    app, resources={r"/*": {"origins": "*"}},
    headers=['Content-Type', 'X-Requested-With', 'Authorization']
)

# Config Api REST
api = Api(app, decorators=[csrf.exempt])

# Config email
mail = Mail()
mail.init_app(app)

# Flask login instance
login_manager = flask_login.LoginManager()
login_manager.init_app(app)


def load_admin():
    """
    Configuration admin
    """
    from apps.auth.controllers import MyAdminIndexView
    admin = Admin(
        app, name='Admin', index_view=MyAdminIndexView(),
        template_mode='bootstrap3', base_template='admin_master.html',
    )

    return admin


admin = load_admin()


def import_modules():
    """
    Import modules admin and controllers
    """
    from apps import admin, api, urls


# Import modules necessarys
import_modules()

if __name__ == "__main__":
    app.run()
