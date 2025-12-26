import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime


# ==========================================
# Database Connection (類似 Django settings)
# ==========================================
DATABASE_CONFIG = {
    'host': 'YOUR_RDS_ENDPOINT',
    'port': 5432,
    'database': 'testdb',
    'user': 'postgres',
    'password': 'MyPassword123!',
}


class DatabaseConnection:
    """資料庫連線管理 (類似 Django 的 connection)"""
    
    def __init__(self):
        self.conn = None
        self.cursor = None
    
    def __enter__(self):
        self.conn = psycopg2.connect(**DATABASE_CONFIG)
        self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
        return self.cursor
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None:
            self.conn.commit()
        else:
            self.conn.rollback()
        self.cursor.close()
        self.conn.close()


# ==========================================
# Models (類似 Django Models)
# ==========================================

class ProductManager:
    """Product 管理器 (類似 Django Manager)"""
    
    @staticmethod
    def create_table():
        """建立表格 (類似 migrate)"""
        with DatabaseConnection() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS products (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(200) NOT NULL,
                    price DECIMAL(10, 2) NOT NULL,
                    stock INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print("✅ Table 'products' created")
    
    @staticmethod
    def create(name, price, stock=0):
        """新增產品 (類似 Model.objects.create)"""
        with DatabaseConnection() as cursor:
            cursor.execute("""
                INSERT INTO products (name, price, stock)
                VALUES (%s, %s, %s)
                RETURNING id, name, price, stock, created_at;
            """, (name, price, stock))
            return cursor.fetchone()
    
    @staticmethod
    def all():
        """取得所有產品 (類似 Model.objects.all())"""
        with DatabaseConnection() as cursor:
            cursor.execute("SELECT * FROM products ORDER BY id;")
            return cursor.fetchall()
    
    @staticmethod
    def filter(name=None, min_price=None):
        """篩選產品 (類似 Model.objects.filter())"""
        with DatabaseConnection() as cursor:
            query = "SELECT * FROM products WHERE 1=1"
            params = []
            
            if name:
                query += " AND name ILIKE %s"
                params.append(f"%{name}%")
            
            if min_price:
                query += " AND price >= %s"
                params.append(min_price)
            
            query += " ORDER BY id;"
            cursor.execute(query, params)
            return cursor.fetchall()
    
    @staticmethod
    def update(product_id, **kwargs):
        """更新產品 (類似 instance.save())"""
        with DatabaseConnection() as cursor:
            set_clause = ", ".join([f"{k} = %s" for k in kwargs.keys()])
            query = f"UPDATE products SET {set_clause}, updated_at = CURRENT_TIMESTAMP WHERE id = %s RETURNING *;"
            params = list(kwargs.values()) + [product_id]
            cursor.execute(query, params)
            return cursor.fetchone()
    
    @staticmethod
    def delete(product_id):
        """刪除產品 (類似 instance.delete())"""
        with DatabaseConnection() as cursor:
            cursor.execute("DELETE FROM products WHERE id = %s;", (product_id,))
            return cursor.rowcount > 0