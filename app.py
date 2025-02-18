from flask import Flask, render_template, request, redirect, url_for
import sqlite3

app = Flask(__name__)

DATABASE = 'votes.db'

def get_db():
    conn = sqlite3.connect(DATABASE)
    return conn

@app.route('/')
def index():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM polls')
    polls = cursor.fetchall()
    conn.close()
    return render_template('index.html', polls=polls)

@app.route('/vote/<int:poll_id>', methods=['GET', 'POST'])
def vote(poll_id):
    conn = get_db()
    cursor = conn.cursor()
    if request.method == 'POST':
        option = request.form['option']
        cursor.execute('INSERT INTO votes (poll_id, option) VALUES (?, ?)', (poll_id, option))
        conn.commit()
        conn.close()
        return redirect(url_for('index'))
    cursor.execute('SELECT * FROM options WHERE poll_id = ?', (poll_id,))
    options = cursor.fetchall()
    conn.close()
    return render_template('vote.html', poll_id=poll_id, options=options)

@app.route('/results/<int:poll_id>')
def results(poll_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT option, COUNT(option) FROM votes WHERE poll_id = ? GROUP BY option', (poll_id,))
    results = cursor.fetchall()
    conn.close()
    return render_template('results.html', poll_id=poll_id, results=results)

if __name__ == '__main__':
    with app.app_context():
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS polls (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                question TEXT NOT NULL
            )
        ''')
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS options (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                poll_id INTEGER NOT NULL,
                option TEXT NOT NULL,
                FOREIGN KEY (poll_id) REFERENCES polls (id)
            )
        ''')
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS votes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                poll_id INTEGER NOT NULL,
                option TEXT NOT NULL,
                FOREIGN KEY (poll_id) REFERENCES polls (id)
            )
        ''')
        conn.commit()
        conn.close()
    app.run(host='0.0.0.0', port=5000, debug=True)

