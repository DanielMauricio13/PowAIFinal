import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

const today = new Date().toISOString().split("T")[0];

function App() {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem("powai-user");
    return saved ? JSON.parse(saved) : { name: "", goal: "Build Muscle" };
  });
  const [activeTab, setActiveTab] = useState("workout");
  const [workouts, setWorkouts] = useState(() => {
    const saved = localStorage.getItem("powai-workouts");
    return saved ? JSON.parse(saved) : [];
  });
  const [meals, setMeals] = useState(() => {
    const saved = localStorage.getItem("powai-meals");
    return saved ? JSON.parse(saved) : [];
  });

  const calories = useMemo(
    () => meals.reduce((acc, meal) => acc + Number(meal.calories || 0), 0),
    [meals]
  );

  const saveUser = (next) => {
    setUser(next);
    localStorage.setItem("powai-user", JSON.stringify(next));
  };

  const addWorkout = (e) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const newWorkout = {
      id: crypto.randomUUID(),
      date: form.get("date"),
      focus: form.get("focus"),
      duration: form.get("duration")
    };
    const next = [newWorkout, ...workouts];
    setWorkouts(next);
    localStorage.setItem("powai-workouts", JSON.stringify(next));
    e.currentTarget.reset();
  };

  const addMeal = (e) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const newMeal = {
      id: crypto.randomUUID(),
      name: form.get("name"),
      calories: form.get("calories")
    };
    const next = [newMeal, ...meals];
    setMeals(next);
    localStorage.setItem("powai-meals", JSON.stringify(next));
    e.currentTarget.reset();
  };

  const isOnboarded = user.name.trim().length > 0;

  if (!isOnboarded) {
    return (
      <main className="shell centered">
        <section className="card">
          <h1>PowAI</h1>
          <p>Create your profile to start training and tracking nutrition.</p>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const form = new FormData(e.currentTarget);
              saveUser({
                name: form.get("name"),
                goal: form.get("goal")
              });
            }}
            className="stack"
          >
            <input name="name" placeholder="Your name" required />
            <select name="goal" defaultValue="Build Muscle">
              <option>Build Muscle</option>
              <option>Lose Fat</option>
              <option>Improve Endurance</option>
            </select>
            <button type="submit">Start</button>
          </form>
        </section>
      </main>
    );
  }

  return (
    <main className="shell">
      <header className="topbar">
        <div>
          <h1>PowAI Dashboard</h1>
          <p>
            Welcome back, {user.name} · Goal: <strong>{user.goal}</strong>
          </p>
        </div>
        <button onClick={() => saveUser({ name: "", goal: "Build Muscle" })}>Log out</button>
      </header>

      <nav className="tabs">
        {[
          ["workout", "Workouts"],
          ["nutrition", "Nutrition"],
          ["settings", "Settings"]
        ].map(([id, label]) => (
          <button
            key={id}
            className={activeTab === id ? "active" : ""}
            onClick={() => setActiveTab(id)}
          >
            {label}
          </button>
        ))}
      </nav>

      {activeTab === "workout" && (
        <section className="grid">
          <article className="card">
            <h2>Log Workout</h2>
            <form className="stack" onSubmit={addWorkout}>
              <input type="date" name="date" defaultValue={today} required />
              <input name="focus" placeholder="Focus (Upper body, Cardio...)" required />
              <input type="number" min="5" name="duration" placeholder="Duration (min)" required />
              <button type="submit">Save Workout</button>
            </form>
          </article>

          <article className="card">
            <h2>Recent Workouts</h2>
            <ul className="list">
              {workouts.length === 0 && <li>No workouts logged yet.</li>}
              {workouts.map((w) => (
                <li key={w.id}>
                  <strong>{w.focus}</strong>
                  <span>{w.date}</span>
                  <span>{w.duration} min</span>
                </li>
              ))}
            </ul>
          </article>
        </section>
      )}

      {activeTab === "nutrition" && (
        <section className="grid">
          <article className="card">
            <h2>Daily Calories</h2>
            <p className="metric">{calories} kcal</p>
            <form className="stack" onSubmit={addMeal}>
              <input name="name" placeholder="Meal or food item" required />
              <input type="number" name="calories" min="0" placeholder="Calories" required />
              <button type="submit">Add Meal</button>
            </form>
          </article>
          <article className="card">
            <h2>Meal Log</h2>
            <ul className="list">
              {meals.length === 0 && <li>No meals added yet.</li>}
              {meals.map((meal) => (
                <li key={meal.id}>
                  <strong>{meal.name}</strong>
                  <span>{meal.calories} kcal</span>
                </li>
              ))}
            </ul>
          </article>
        </section>
      )}

      {activeTab === "settings" && (
        <section className="card stack">
          <h2>Profile Settings</h2>
          <form
            className="stack"
            onSubmit={(e) => {
              e.preventDefault();
              const form = new FormData(e.currentTarget);
              saveUser({ name: form.get("name"), goal: form.get("goal") });
            }}
          >
            <input name="name" defaultValue={user.name} required />
            <select name="goal" defaultValue={user.goal}>
              <option>Build Muscle</option>
              <option>Lose Fat</option>
              <option>Improve Endurance</option>
            </select>
            <button type="submit">Save Profile</button>
          </form>
        </section>
      )}
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
