from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, Enum
from sqlalchemy.orm import sessionmaker, relationship, declarative_base
import enum


DATABASE_URL = "mysql+pymysql://root:2609@localhost:3306/vk"  
engine = create_engine(DATABASE_URL)

Base = declarative_base()


class FriendshipStatus(enum.Enum):
    SENT = "отправлено"
    ACCEPTED = "принято"
    DECLINED = "отклонено"
    REMOVED = "удалено"


class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)

    friends = relationship('Friendship', back_populates='user', cascade="all, delete-orphan")
    posts = relationship('Post', back_populates='user', cascade="all, delete-orphan")


class Friendship(Base):
    __tablename__ = 'friendships'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    friend_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    status = Column(Enum(FriendshipStatus), default=FriendshipStatus.SENT)

    user = relationship('User', back_populates='friends')


class Post(Base):
    __tablename__ = 'posts'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    content = Column(String, nullable=False)

    user = relationship('User', back_populates='posts')


Base.metadata.create_all(engine)


Session = sessionmaker(bind=engine)
session = Session()


def create_user(name):
    user = User(name=name)
    session.add(user)
    session.commit()
    return user


def add_friend(user_id, friend_id):
    friendship = Friendship(user_id=user_id, friend_id=friend_id, status=FriendshipStatus.SENT)
    session.add(friendship)
    session.commit()


def update_friendship_status(user_id, friend_id, status):
    friendship = session.query(Friendship).filter(
        Friendship.user_id == user_id,
        Friendship.friend_id == friend_id
    ).first()
    if friendship:
        friendship.status = status
        session.commit()


def add_post(user_id, content):
    post = Post(user_id=user_id, content=content)
    session.add(post)
    session.commit()


def get_user_info(user_id):
    user = session.query(User).filter(User.id == user_id).first()
    if user:
        print(f"Пользователь: {user.name}")
    else:
        print("Пользователь не найден.")


def get_friends(user_id):
    user = session.query(User).filter(User.id == user_id).first()
    if user:
        print("Друзья:")
        for friendship in user.friends:
            friend = session.query(User).filter(User.id == friendship.friend_id).first()
            if friend:
                print(f"{friend.name} - Статус: {friendship.status.value}")
    else:
        print("Пользователь не найден.")


def get_posts(user_id):
    user = session.query(User).filter(User.id == user_id).first()
    if user:
        print("Посты:")
        for post in user.posts:
            print(post.content)
    else:
        print("Пользователь не найден.")

if __name__ == "__main__":
    
    
    user1 = create_user("Alice")
    user2 = create_user("Bob")
    
    add_friend(user1.id, user2.id)
    add_post(user1.id, "Привет,дружище")
    
    get_user_info(user1.id)
    get_friends(user1.id)
    get_posts(user1.id)

    print("\n Обновление статуса дружбы:")
    update_friendship_status(user1.id, user2.id, FriendshipStatus.ACCEPTED)
    get_friends(user1.id)