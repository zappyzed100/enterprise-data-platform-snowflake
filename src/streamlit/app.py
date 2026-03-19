import streamlit as st
from snowflake.snowpark import Session

# ページ設定
st.set_page_config(page_title="Logistics Cost Optimizer", layout="wide")

st.title("🚚 Logistics Cost Optimizer")
st.write("Snowflake Gold Layer への接続テスト")


# Snowpark Session の初期化
@st.cache_resource
def create_session():
    # .streamlit/secrets.toml から設定を読み込む
    return Session.builder.configs(st.secrets["connections"]["snowpark"]).create()


try:
    session = create_session()
    st.success("Snowflake への接続に成功しました！")

    # Gold 層（fct_delivery_analysis）から 10 件取得
    st.subheader("Latest Delivery Analysis (Sample 10)")
    df = session.table("fct_delivery_analysis").limit(10).to_pandas()

    # データの表示
    st.dataframe(df, use_container_width=True)

except Exception as e:
    st.error(f"接続エラーが発生しました: {e}")

finally:
    # セッションのクローズ（キャッシュする場合は管理に注意）
    pass
