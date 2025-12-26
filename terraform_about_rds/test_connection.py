#!/usr/bin/env python3
"""
RDS 連線測試腳本

使用方式:
1. 上傳到 EC2: scp -i your-key.pem test_connection.py ec2-user@<EC2_IP>:~/rds-test/
2. 執行: python3 test_connection.py
"""

import psycopg2
import sys

# ==========================================
# 資料庫連線設定
# ==========================================
# 部署後,從 terraform output 取得這些值

DB_HOST = "YOUR_RDS_ENDPOINT"  # 例如: my-postgres-db.xxxxx.ap-northeast-1.rds.amazonaws.com
DB_PORT = 5432
DB_NAME = "testdb"
DB_USER = "postgres"
DB_PASSWORD = "MyPassword123!"


def test_connection():
    """測試 RDS 連線"""
    
    print("="*60)
    print("RDS 連線測試")
    print("="*60)
    print(f"Host: {DB_HOST}")
    print(f"Port: {DB_PORT}")
    print(f"Database: {DB_NAME}")
    print(f"User: {DB_USER}")
    print("="*60)
    
    try:
        # 建立連線
        print("\n[1/5] 正在連線到資料庫...")
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=10
        )
        print("✅ 連線成功!")
        
        cursor = conn.cursor()
        
        # 測試 1: 查詢資料庫版本
        print("\n[2/5] 查詢 PostgreSQL 版本...")
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✅ {version[:50]}...")
        
        # 測試 2: 建立測試表格
        print("\n[3/5] 建立測試表格...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS test_data (
                id SERIAL PRIMARY KEY,
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        print("✅ 表格建立成功!")
        
        # 測試 3: 插入測試資料
        print("\n[4/5] 插入測試資料...")
        cursor.execute("""
            INSERT INTO test_data (message) 
            VALUES ('Hello from EC2!'), ('RDS connection test'), ('Success!')
            RETURNING id, message;
        """)
        inserted = cursor.fetchall()
        conn.commit()
        print(f"✅ 插入 {len(inserted)} 筆資料")
        for row in inserted:
            print(f"   - ID {row[0]}: {row[1]}")
        
        # 測試 4: 查詢資料
        print("\n[5/5] 查詢所有資料...")
        cursor.execute("SELECT id, message, created_at FROM test_data ORDER BY id;")
        rows = cursor.fetchall()
        print(f"✅ 查詢到 {len(rows)} 筆資料:")
        for row in rows:
            print(f"   - ID {row[0]}: {row[1]} ({row[2]})")
        
        # 關閉連線
        cursor.close()
        conn.close()
        
        print("\n" + "="*60)
        print("✅ 所有測試通過!")
        print("="*60)
        
        return True
        
    except psycopg2.Error as e:
        print(f"\n❌ 資料庫錯誤: {e}")
        return False
    except Exception as e:
        print(f"\n❌ 錯誤: {e}")
        return False


def cleanup():
    """清理測試資料"""
    
    print("\n是否要清理測試資料? (y/N): ", end="")
    choice = input().lower()
    
    if choice != 'y':
        print("保留測試資料")
        return
    
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cursor = conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS test_data;")
        conn.commit()
        cursor.close()
        conn.close()
        print("✅ 測試資料已清理")
    except Exception as e:
        print(f"❌ 清理失敗: {e}")


if __name__ == "__main__":
    # 檢查設定
    if DB_HOST == "YOUR_RDS_ENDPOINT":
        print("❌ 錯誤: 請先設定 DB_HOST!")
        print("\n請編輯此檔案,將 DB_HOST 改為你的 RDS endpoint")
        print("可以從 terraform output 取得 RDS endpoint")
        sys.exit(1)
    
    # 執行測試
    success = test_connection()
    
    # 是否清理
    if success:
        cleanup()
    
    sys.exit(0 if success else 1)
