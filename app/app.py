import time
import os
from flask import Flask, render_template, flash, redirect, request, url_for
from flask_sqlalchemy import SQLAlchemy

DBUSER = os.environ['POSTGRES_USER']
DBPASS = os.environ['POSTGRES_PASSWORD']
DBNAME = os.environ['POSTGRES_DB']
DBHOST = 'db-server'
DBPORT = '5432'

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = \
    'postgresql+psycopg2://{user}:{passwd}@{host}:{port}/{db}'.format(
        user=DBUSER,
        passwd=DBPASS,
        host=DBHOST,
        port=DBPORT,
        db=DBNAME)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.secret_key = 'foobarbaz'


db = SQLAlchemy(app)


class inputs(db.Model):
    id = db.Column('input_id', db.Integer, primary_key=True)
    input = db.Column(db.String(100))

    def __init__(self, input):
        self.input = input

def database_initialization_sequence():
    db.create_all()
    test_rec = inputs(
            'xyz')

    db.session.add(test_rec)
    db.session.rollback()
    db.session.commit()

@app.route('/', methods=['GET', 'POST'])
def home():
    if request.method == 'POST':
        if not request.form['input']:
            flash('Please enter all the fields', 'error')
        else:
            input = inputs(
                    request.form['input'])

            db.session.add(input)
            db.session.commit()
            flash('Record was succesfully added')
            return redirect(url_for('home'))
    return render_template('show_all.html', inputs=inputs.query.all())


if __name__ == '__main__':
    dbstatus = False
    while dbstatus == False:
        try:
            db.create_all()
        except:
            time.sleep(2)
        else:
            dbstatus = True
    database_initialization_sequence()
    app.run(debug=True, host='0.0.0.0')
