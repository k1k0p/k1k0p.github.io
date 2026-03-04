import tkinter as tk
from tkinter import ttk, messagebox, simpledialog, scrolledtext
from tkcalendar import Calendar, DateEntry  # Para selecionar datas
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import text

class DatabaseApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Aplicação CRUD")
        self.root.geometry("900x600")

        self.engine = None
        self.Session = None

        self.create_main_layout()

    def create_main_layout(self):
        # Título principal
        title_label = tk.Label(self.root, text="Aplicação CRUD com Tkinter e SQLAlchemy",
                               font=("Arial", 18, "bold"), fg="blue")
        title_label.pack(pady=10)

        # Frame de botões
        button_frame = tk.Frame(self.root, padx=10, pady=10)
        button_frame.pack()

        connect_button = ttk.Button(button_frame, text="Conectar à Base de Dados", command=self.connect_to_db)
        connect_button.grid(row=0, column=0, padx=10, pady=5)


        show_resources_button = ttk.Button(button_frame, text="Mostrar Recursos e Estado", command=self.show_resources_state)
        show_resources_button.grid(row=1, column=2, padx=10, pady=5)

        gerir_reservas_button = ttk.Button(button_frame, text="Gerir Reservas", command=self.manage_reservations)
        gerir_reservas_button.grid(row=1, column=1, padx=10, pady=5)

        register_reserva_button = ttk.Button(button_frame, text="Registrar Reserva", command=self.register_reservation)
        register_reserva_button.grid(row=1, column=0, padx=10, pady=5)

        register_requisicao_button = ttk.Button(button_frame, text="Registrar Requisição", command=self.register_requisicao)
        register_requisicao_button.grid(row=1, column=3, padx=10, pady=5)

        exit_button = ttk.Button(button_frame, text="Sair", command=self.root.quit)
        exit_button.grid(row=0, column=1, padx=10, pady=5)

        # Área de log
        self.log_area = scrolledtext.ScrolledText(self.root, width=100, height=15)
        self.log_area.pack(pady=10)
        self.log_area.insert(tk.END, "Bem-vindo! Use os botões acima para executar operações.\n")

    def log_message(self, message):
        self.log_area.insert(tk.END, f"{message}\n")
        self.log_area.see(tk.END)

    def connect_to_db(self):
        try:
            ip = "192.168.100.14"
            user = "User_BD_PL4_03"
            password = "diubi:2024!BD!PL4_03"
            database = "BD_PL4_03"

            # Conectar usando SQLAlchemy
            connection_string = f"mssql+pyodbc://{user}:{password}@{ip}/{database}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
            self.engine = create_engine(connection_string)
            self.Session = sessionmaker(bind=self.engine)

            # Testar a conexão
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))  # Query ajustada para ser executável

            self.log_message("Ligação efetuada com sucesso!")
            messagebox.showinfo("Sucesso", "Ligação efetuada com sucesso!")
        except Exception as e:
            self.log_message(f"Erro na ligação: {e}")
            messagebox.showerror("Erro na ligação", f"Erro no acesso à base de dados: {e}")

    def show_resources_state(self):
        if self.Session:
            try:
                # Defina a consulta para mostrar os recursos e seus estados
                query = text("""
                SELECT ResID, ResDesc, State, ID, User FROM ResourceState
            
                """)

                session = self.Session()
                result = session.execute(query).fetchall()

                # Criar a janela para mostrar os resultados
                result_window = tk.Toplevel(self.root)
                result_window.title("Recursos e Estado")

                # Criar o Treeview para exibir os dados
                tree = ttk.Treeview(result_window, columns=("ResID", "ResDesc", "State", "ID", "User"), show="headings")
                tree.heading("ResID", text="ID Recurso")
                tree.heading("ResDesc", text="Nome Recurso")
                tree.heading("State", text="Estado")
                tree.heading("ID", text="ID Utilizador")
                tree.heading("User", text="Nome Utilizador")
                tree.pack(padx=10, pady=10)

                # Preencher o Treeview com os dados
                for row in result:
                    tree.insert("", "end", values=(row[0], row[1], row[2], row[3], row[4]))

                session.close()
            except Exception as e:
                self.log_message(f"Erro ao consultar recursos: {e}")
                messagebox.showerror("Erro", f"Erro ao consultar recursos: {e}")
        else:
            messagebox.showwarning("Aviso", "Ligue-se à base de dados primeiro.")


    def manage_reservations(self):
        if self.Session:
            try:
                # Define a consulta para mostrar as reservas
                query = text("""
                SELECT id, timestamp, data_inicio, duracao, estado_reserva, id_utilizador FROM reserva
                """)

                session = self.Session()
                result = session.execute(query).fetchall()

                # Criar a janela para mostrar os resultados
                result_window = tk.Toplevel(self.root)
                result_window.title("Gerir Reservas")

                # Criar o Treeview para exibir os dados
                tree = ttk.Treeview(result_window, columns=("id", "timestamp", "data_inicio", "duracao", "estado_reserva", "id_utilizador"), show="headings")
                tree.heading("id", text="ID")
                tree.heading("timestamp", text="Timestamp")
                tree.heading("data_inicio", text="Data Início")
                tree.heading("duracao", text="Duração")
                tree.heading("estado_reserva", text="Estado")
                tree.heading("id_utilizador", text="ID Utilizador")
                tree.pack(padx=10, pady=10)

                # Função para alterar o estado da reserva
                def change_status(reserva_id, current_status):
                    def update_status():
                        new_status = status_dropdown.get()
                        if new_status in ["active", "satisfied", "forgotten"]:
                            try:
                                # Atualizar estado na base de dados
                                update_query = text(f"UPDATE reserva SET estado_reserva = :new_status WHERE id = :reserva_id")
                                session.execute(update_query, {"new_status": new_status, "reserva_id": reserva_id})
                                session.commit()
                                self.log_message(f"Estado da reserva {reserva_id} alterado para {new_status}")
                                messagebox.showinfo("Sucesso", f"Estado da reserva {reserva_id} alterado para {new_status}")
                                result_window.destroy()  # Fechar a janela após a atualização
                            except Exception as e:
                                self.log_message(f"Erro ao alterar o estado: {e}")
                                messagebox.showerror("Erro", f"Erro ao alterar o estado: {e}")
                        else:
                            messagebox.showerror("Erro", "Estado inválido. Escolha entre 'active', 'satisfied' ou 'forgotten'.")

                    # Criar Dropdown para selecionar novo estado
                    status_label = tk.Label(result_window, text="Escolher novo estado:")
                    status_label.pack(pady=5)

                    status_dropdown = ttk.Combobox(result_window, values=["active", "satisfied", "forgotten"])
                    status_dropdown.set(current_status)  # Definir o estado atual como valor padrão
                    status_dropdown.pack(pady=5)

                    # Botão para atualizar o estado
                    update_button = ttk.Button(result_window, text="Atualizar Estado", command=update_status)
                    update_button.pack(pady=5)

                # Preencher o Treeview com os dados
                for row in result:
                    tree.insert("", "end", values=(row[0], row[1], row[2], row[3], row[4], row[5]))

                    # Criar botão de alteração de estado ao lado de cada linha
                    change_button = ttk.Button(result_window, text="Alterar Estado", command=lambda r_id=row[0], r_estado=row[4]: change_status(r_id, r_estado))
                    change_button.pack(pady=5)

                session.close()
            except Exception as e:
                self.log_message(f"Erro ao consultar reservas: {e}")
                messagebox.showerror("Erro", f"Erro ao consultar reservas: {e}")
        else:
            messagebox.showwarning("Aviso", "Ligue-se à base de dados primeiro.")

   

    def register_reservation(self):
        if self.Session:
            try:
                session = self.Session()

                # Criar a janela para a reserva
                new_reservation_window = tk.Toplevel(self.root)
                new_reservation_window.title("Registrar Nova Reserva")
                new_reservation_window.geometry("600x600")

                # Seleção de utilizador
                user_label = tk.Label(new_reservation_window, text="Selecione o Utilizador:")
                user_label.pack(pady=5)
                user_query = text("SELECT id_utilizador, nome FROM Utilizador")
                users = session.execute(user_query).fetchall()
                user_dropdown = ttk.Combobox(new_reservation_window, values=[f"{u.id_utilizador} - {u.nome}" for u in users])
                user_dropdown.pack(pady=5)

                # Seleção de equipamentos disponíveis com checkboxes
                equip_label = tk.Label(new_reservation_window, text="Selecione Equipamentos Disponíveis:")
                equip_label.pack(pady=5)

                equip_query = text("SELECT id_equipamento, descricao FROM equipamento WHERE estado_equipamento IN (0, 1)")
                equipment = session.execute(equip_query).fetchall()

                equipment_vars = {}
                equipment_frame = tk.Frame(new_reservation_window)
                equipment_frame.pack(pady=10)

                for eq in equipment:
                    equip_id = eq.id_equipamento
                    equip_desc = eq.descricao
                    equipment_vars[equip_id] = tk.IntVar(value=0)
                    tk.Checkbutton(equipment_frame, text=f"{equip_id} - {equip_desc}", variable=equipment_vars[equip_id]).pack(anchor="w")

                # Seleção de data e hora de início
                start_date_label = tk.Label(new_reservation_window, text="Data e Hora de Início (A partir do presente):")
                start_date_label.pack(pady=5)
                start_date_entry = DateEntry(new_reservation_window, width=12, background="darkblue", foreground="white", borderwidth=2, date_pattern='yyyy-mm-dd')
                start_date_entry.set_date(datetime.today())
                start_date_entry.pack(pady=5)

                start_time_entry = tk.Entry(new_reservation_window, width=20)
                start_time_entry.insert(0, datetime.now().strftime('%H:%M'))
                start_time_entry.pack(pady=5)

                # Input para a duração da reserva
                duration_label = tk.Label(new_reservation_window, text="Duração (em minutos):")
                duration_label.pack(pady=5)
                duration_entry = tk.Entry(new_reservation_window)
                duration_entry.pack(pady=5)

                # Função para guardar a reserva
                def save_reservation():
                    try:
                        # Garantir que selected_user é tratado como string (ID do utilizador é varchar)
                        selected_user = user_dropdown.get().split(" - ")[0]  # Usar o ID como string
                        selected_equipment = [equip_id for equip_id, var in equipment_vars.items() if var.get() == 1]
                        start_date = start_date_entry.get()
                        start_time = start_time_entry.get()
                        duration = int(duration_entry.get())

                        if not selected_equipment:
                            messagebox.showwarning("Aviso", "Selecione ao menos um equipamento.")
                            return

                        if not start_date or not start_time or not duration:
                            messagebox.showwarning("Aviso", "Preencha todos os campos obrigatórios.")
                            return

                        full_start_datetime = f"{start_date} {start_time}"

                        # Iniciar a transação
                        with session.begin():
                            # Inserir a reserva
                            new_reservation_query = text("""
                                INSERT INTO reserva (timestamp, data_inicio, duracao, estado_reserva, id_utilizador)
                                VALUES (GETDATE(), :data_inicio, :duracao, 'active', :id_utilizador);
                            """)
                            session.execute(new_reservation_query, {
                                "data_inicio": full_start_datetime,
                                "duracao": duration,
                                "id_utilizador": selected_user  # ID do utilizador como string
                            })

                            # Obter o ID da nova reserva
                            reservation_id_query = text("SELECT TOP 1 id FROM reserva ORDER BY timestamp DESC")
                            reservation_id = session.execute(reservation_id_query).scalar()

                            if reservation_id is None:
                                raise Exception("Falha ao obter o ID da reserva após inserção.")

                            # Inserir equipamentos associados à reserva
                            for equipamento_id in selected_equipment:
                                equipamento_query = text("""
                                    INSERT INTO reserva_equipamento (id_equipamento, id_reserva, imprescindivel)
                                    VALUES (:equipamento_id, :reservation_id, 1);
                                """)
                                session.execute(equipamento_query, {
                                    "equipamento_id": int(equipamento_id),  # ID do equipamento como inteiro
                                    "reservation_id": reservation_id
                                })

                        # Confirmar a transação
                        messagebox.showinfo("Sucesso", "Reserva registrada com sucesso!")
                        new_reservation_window.destroy()

                    except Exception as e:
                        session.rollback()
                        self.log_message(f"Erro ao registrar reserva: {e}")
                        messagebox.showerror("Erro", f"Erro ao registrar reserva: {e}")

                # Botão para gaurdar a reserva
                save_button = ttk.Button(new_reservation_window, text="Guardar Reserva", command=save_reservation)
                save_button.pack(pady=10)

            except Exception as e:
                self.log_message(f"Erro ao registrar nova reserva: {e}")
                messagebox.showerror("Erro", f"Erro ao registrar nova reserva: {e}")

        else:
            messagebox.showwarning("Aviso", "Ligue-se à base de dados primeiro.")


    def register_requisicao(self):
        if self.Session:
            try:
                session = self.Session()

                # Criar janela para registrar requisição
                new_requisicao_window = tk.Toplevel(self.root)
                new_requisicao_window.title("Registrar Nova Requisição")
                new_requisicao_window.geometry("600x400")

                # Seleção de reservas disponíveis para criar requisição
                reservas_label = tk.Label(new_requisicao_window, text="Selecione uma Reserva (Ativa):")
                reservas_label.pack(pady=5)

                reserva_query = text("SELECT id, data_inicio, duracao FROM reserva WHERE estado_reserva = 'active'")
                reservas = session.execute(reserva_query).fetchall()

                reserva_dropdown = ttk.Combobox(new_requisicao_window, values=[
                    f"{r.id} - {r.data_inicio} ({r.duracao} minutos)" for r in reservas
                ])
                reserva_dropdown.pack(pady=5)

                # Função para registrar a requisição
                def save_requisicao():
                    try:
                        selected_reserva = reserva_dropdown.get().split(" - ")[0]  # Obter ID da reserva selecionada
                        if not selected_reserva:
                            messagebox.showwarning("Aviso", "Selecione uma reserva para continuar.")
                            return

                        
                        # Iniciar a transação
                        if not session.is_active:
                            session.begin()

                        # Atualizar o estado da reserva para 'satisfied'
                        create_requisicao_query = text("""
                            UPDATE reserva SET estado_reserva = 'satisfied'
                            WHERE id = :reserva_id
                        """)
                        session.execute(create_requisicao_query, {"reserva_id": selected_reserva})

                        # Confirmar a transação
                        session.commit()
                        messagebox.showinfo("Sucesso", "Requisição registrada com sucesso!")
                        new_requisicao_window.destroy()

                    except Exception as e:
                        session.rollback()
                        self.log_message(f"Erro ao registrar requisição: {e}")
                        messagebox.showerror("Erro", f"Erro ao registrar requisição: {e}")

                    finally:
                        session.close()

                # Botão para guardar a requisição
                save_button = ttk.Button(new_requisicao_window, text="Registrar Requisição", command=save_requisicao)
                save_button.pack(pady=10)

            except Exception as e:
                self.log_message(f"Erro ao abrir a interface de registro de requisição: {e}")
                messagebox.showerror("Erro", f"Erro ao abrir a interface: {e}")
        else:
            messagebox.showwarning("Aviso", "Ligue-se à base de dados primeiro.")

    def register_return(self):
        if self.Session:
            try:
                session = self.Session()

                # Criar janela para registrar devolução
                return_window = tk.Toplevel(self.root)
                return_window.title("Registrar Devolução de Equipamento")
                return_window.geometry("600x400")

                # Seleção de requisições ativas
                requisicoes_label = tk.Label(return_window, text="Selecione uma Requisição Ativa:")
                requisicoes_label.pack(pady=5)

                requisicao_query = text("""
                    SELECT r.id, r.data_criacao, u.nome
                    FROM requisicao r
                    JOIN reserva rs ON r.id_reserva = rs.id
                    JOIN Utilizador u ON rs.id_utilizador = u.id_utilizador
                    WHERE r.estado_requisicao = 'active'
                """)
                requisicoes = session.execute(requisicao_query).fetchall()

                requisicao_dropdown = ttk.Combobox(return_window, values=[
                    f"{r.id} - {r.data_criacao} ({r.nome})" for r in requisicoes
                ])
                requisicao_dropdown.pack(pady=5)

                # Função para registrar a devolução
                def save_return():
                    try:
                        selected_requisicao = requisicao_dropdown.get().split(" - ")[0]  # Obter ID da requisição selecionada
                        if not selected_requisicao:
                            messagebox.showwarning("Aviso", "Selecione uma requisição para continuar.")
                            return

                        # Iniciar a transação
                        if not session.is_active:
                            session.begin()

                        # Atualizar o estado da requisição para 'returned' e liberar os equipamentos
                        return_query = text("""
                            UPDATE requisicao
                            SET estado_requisicao = 'canceled'
                            WHERE id = :requisicao_id
                        """)
                        session.execute(return_query, {"requisicao_id": selected_requisicao})

                        # Liberar os equipamentos associados à requisição
                        release_equipments_query = text("""
                            UPDATE equipamento
                            SET estado_equipamento = 0
                            WHERE id_equipamento IN (
                                SELECT id_equipamento
                                FROM requisicao_equipamento
                                WHERE id_requisicao = :requisicao_id
                            )
                        """)
                        session.execute(release_equipments_query, {"requisicao_id": selected_requisicao})

                        # Confirmar a transação
                        session.commit()
                        messagebox.showinfo("Sucesso", "Devolução registrada com sucesso!")
                        return_window.destroy()

                    except Exception as e:
                        session.rollback()
                        self.log_message(f"Erro ao registrar devolução: {e}")
                        messagebox.showerror("Erro", f"Erro ao registrar devolução: {e}")

                    finally:
                        session.close()

                # Botão para guardar a devolução
                save_button = ttk.Button(return_window, text="Registrar Devolução", command=save_return)
                save_button.pack(pady=10)

            except Exception as e:
                self.log_message(f"Erro ao abrir a interface de registro de devolução: {e}")
                messagebox.showerror("Erro", f"Erro ao abrir a interface: {e}")
        else:
            messagebox.showwarning("Aviso", "Ligue-se à base de dados primeiro.")


if __name__ == "__main__":
    root = tk.Tk()
    app = DatabaseApp(root)
    root.mainloop()
